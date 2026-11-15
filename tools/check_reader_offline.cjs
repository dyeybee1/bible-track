// Real Chromium: legacy migration, waiting-worker consent and offline assets.
// Run AFTER flutter build web && node tools/build_pwa.cjs.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {spawn} = require('node:child_process');
const assert = require('node:assert/strict');
const {createHash} = require('node:crypto');
const {buildPwa} = require('./build_pwa.cjs');

async function main() {
  const root = path.resolve('build/web');
  const releaseA = JSON.parse(fs.readFileSync(path.join(root, 'version.json'), 'utf8')).buildHash;
  if (!releaseA) throw new Error('Run node tools/build_pwa.cjs after flutter build web');
  const expectedAppA = createHash('sha256').update(fs.readFileSync(path.join(root, 'main.dart.js'))).digest('hex');
  const releaseRoot = path.resolve('build/reader_size/update-release-' + Date.now());
  fs.cpSync(root, releaseRoot, {recursive:true});
  fs.appendFileSync(path.join(releaseRoot, 'main.dart.js'), '\n// Chromium update-flow probe\n');
  fs.appendFileSync(path.join(releaseRoot, 'index.html'), '\n<!-- NEXT_PWA_RELEASE -->\n');
  const releaseB = buildPwa(releaseRoot).version;
  assert.notEqual(releaseB, releaseA);
  let servedRoot = root;
  let legacy = true;
  let smokeNavigations = 0;
  const legacyWorker = `self.addEventListener('install', event => event.waitUntil((async () => {
    const cache = await caches.open('bible-track-reader-legacy-browser-check');
    await cache.addAll(['index.html']); await self.skipWaiting();
  })()));
  self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
  self.addEventListener('fetch', event => {
    if (event.request.mode === 'navigate' || new URL(event.request.url).pathname === '/index.html') {
      event.respondWith(caches.open('bible-track-reader-legacy-browser-check').then(async cache =>
        await cache.match('index.html') || fetch(event.request)));
    }
  });`;
  const chromePath = ['C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].find(fs.existsSync);
  if (!chromePath) throw new Error('Chromium not found');
  const profile = path.resolve('build/reader_size/chrome-' + Date.now());
  fs.mkdirSync(profile, {recursive: true});
  const types = {'.js':'text/javascript', '.html':'text/html', '.json':'application/json',
    '.wasm':'application/wasm', '.png':'image/png', '.ttf':'font/ttf'};
  const server = http.createServer((request, response) => {
    const name = new URL(request.url, 'http://localhost').pathname;
    if (name === '/offline-smoke') {
      smokeNavigations++;
      response.writeHead(200, {'Content-Type':'text/html'});
      return response.end('<!doctype html><title>Reader offline check</title>');
    }
    if (name === '/reader_service_worker.js' && legacy) {
      response.writeHead(200, {'Content-Type':'text/javascript', 'Cache-Control':'no-cache'});
      return response.end(legacyWorker);
    }
    const file = path.resolve(servedRoot, '.' + (name === '/' ? '/index.html' : decodeURIComponent(name)));
    if (!file.startsWith(servedRoot + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
      response.writeHead(404); return response.end('missing');
    }
    response.writeHead(200, {'Content-Type':types[path.extname(file)] || 'application/octet-stream', 'Cache-Control':'no-store'});
    fs.createReadStream(file).pipe(response);
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const origin = 'http://127.0.0.1:' + server.address().port;
  const chrome = spawn(chromePath, ['--headless=new', '--disable-gpu', '--no-first-run',
    '--no-default-browser-check', '--remote-debugging-port=0', '--user-data-dir=' + profile, 'about:blank'],
    {windowsHide:true, stdio:'ignore'});
  let socket;
  let send;
  try {
    const activePort = path.join(profile, 'DevToolsActivePort');
    const deadline = Date.now() + 20000;
    while (!fs.existsSync(activePort)) {
      if (Date.now() > deadline) throw new Error('Chromium startup timed out');
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
    const port = fs.readFileSync(activePort, 'utf8').split('\n')[0];
    const pages = await (await fetch('http://127.0.0.1:' + port + '/json/list')).json();
    const page = pages.find((item) => item.type === 'page');
    socket = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => {socket.addEventListener('open', resolve, {once:true}); socket.addEventListener('error', reject, {once:true});});
    let nextId = 0;
    const pending = new Map();
    socket.addEventListener('message', (event) => {
      const message = JSON.parse(event.data);
      const handler = pending.get(message.id);
      if (handler) {pending.delete(message.id); clearTimeout(handler.timer); message.error ? handler.reject(new Error(message.error.message)) : handler.resolve(message.result);}
    });
    socket.addEventListener('close', () => {
      for (const handler of pending.values()) {clearTimeout(handler.timer); handler.reject(new Error('Chromium closed'));}
      pending.clear();
    });
    send = (method, params = {}) => new Promise((resolve, reject) => {
      const id = ++nextId;
      const timer = setTimeout(() => {pending.delete(id); reject(new Error(method + ' timed out'));}, 90000);
      pending.set(id, {resolve, reject, timer});
      socket.send(JSON.stringify({id, method, params}));
    });
    const evaluate = async (expression) => {
      const result = await send('Runtime.evaluate', {expression, awaitPromise:true, returnByValue:true});
      if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
      return result.result.value;
    };
    await send('Network.enable');
    await send('Network.setCacheDisabled', {cacheDisabled:true});
    await send('Page.navigate', {url:origin + '/offline-smoke'});
    let arrived = false;
    for (let attempt = 0; attempt < 100; attempt++) {
      try {arrived = await evaluate(`location.href === ${JSON.stringify(origin + '/offline-smoke')}`);} catch {}
      if (arrived) break;
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    if (!arrived) throw new Error('Local test page did not load');
    console.log('Installing a legacy cache-first worker, then upgrading without reloading the open page…');
    await evaluate(`(async () => {
      await navigator.serviceWorker.register('/reader_service_worker.js', {updateViaCache:'none'});
      await navigator.serviceWorker.ready;
      if (!navigator.serviceWorker.controller) await new Promise(resolve => navigator.serviceWorker.addEventListener('controllerchange', resolve, {once:true}));
      window.quizAnswers = ['keep this answer'];
    })()`);
    const initialNavigations = smokeNavigations;
    legacy = false;
    const ready = await evaluate(`(async () => {
      const changed = new Promise(resolve => navigator.serviceWorker.addEventListener('controllerchange', resolve, {once:true}));
      await (await navigator.serviceWorker.getRegistration()).update();
      await changed;
      const active=(await navigator.serviceWorker.getRegistration()).active;
      if(active.state!=='activated') await new Promise(resolve=>active.addEventListener('statechange',()=>{
        if(active.state==='activated') resolve();
      }));
      const names = await caches.keys();
      const cache = await caches.open(names.find(name => name.startsWith('bible-track-pwa-')));
      return {controlled:!!navigator.serviceWorker.controller, files:(await cache.keys()).length,
        legacyGone:!names.some(name => name.startsWith('bible-track-reader-')), answers:window.quizAnswers};
    })()`);
    assert(ready.controlled); assert(ready.legacyGone);
    assert.deepEqual(ready.answers, ['keep this answer']);
    assert.equal(smokeNavigations, initialNavigations, 'legacy migration must not reload an open quiz');
    await evaluate(`new Promise((resolve,reject) => {
      const script=document.createElement('script');script.src='/pwa_update.js';script.onload=resolve;script.onerror=reject;document.head.appendChild(script);
    })`);
    await new Promise(resolve => setTimeout(resolve, 100));
    servedRoot = releaseRoot;
    await evaluate('window.bibleTrackPwa.checkForUpdate()');
    const waiting = await evaluate(`(async () => {
      const deadline=Date.now()+60000;
      while(Date.now()<deadline) {
        const reg=await navigator.serviceWorker.getRegistration();
        if(reg.waiting && document.getElementById('bt-pwa-update')) return true;
        await new Promise(resolve=>setTimeout(resolve,50));
      }
      throw Error('Waiting worker and update banner did not appear');
    })()`);
    assert(waiting);
    assert.equal(smokeNavigations, initialNavigations, 'a new release must wait for consent');
    const beforeClick = await evaluate(`(async () => {
      const shell=await (await fetch('/index.html')).text();
      const bytes=await (await fetch('/main.dart.js')).arrayBuffer();
      const appHash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
      document.documentElement.lang='fil';
      await new Promise(resolve=>setTimeout(resolve,0));
      return {newShell:shell.includes('NEXT_PWA_RELEASE'), appHash, answers:window.quizAnswers,
        label:document.querySelector('#bt-pwa-update button').textContent};
    })()`);
    assert(beforeClick.newShell, 'online navigation shell is network-first');
    assert.equal(beforeClick.appHash, expectedAppA, 'compiled app remains on A until consent');
    assert.deepEqual(beforeClick.answers, ['keep this answer']);
    assert.equal(beforeClick.label, 'I-update');
    await evaluate("document.querySelector('#bt-pwa-update button').click()");
    for (let attempt=0; attempt<200 && smokeNavigations===initialNavigations; attempt++) await new Promise(resolve=>setTimeout(resolve,50));
    assert.equal(smokeNavigations, initialNavigations+1, 'one consent causes exactly one reload');
    let activated;
    for(let attempt=0;attempt<100;attempt++) {
      try { activated=await evaluate(`(async()=>{const reg=await navigator.serviceWorker.getRegistration();const names=await caches.keys();return {names,controlled:!!navigator.serviceWorker.controller&&reg.active?.state==='activated'};})()`); } catch {}
      if(activated?.controlled) break;
      await new Promise(resolve=>setTimeout(resolve,50));
    }
    assert(activated.controlled);
    assert.deepEqual(activated.names.filter(name=>name.startsWith('bible-track-pwa-')), ['bible-track-pwa-'+releaseB]);
    await send('Network.emulateNetworkConditions', {offline:true, latency:0, downloadThroughput:0, uploadThroughput:0});
    const offline = await evaluate(`(async () => {
      const web = await (await fetch('assets/assets/bible/web/gen.json')).json();
      const tagalog = await (await fetch('assets/assets/bible/tl1905/gen.json')).json();
      const mapping = await (await fetch('assets/assets/bible/mapping.json')).json();
      const quiz = await (await fetch('assets/assets/questions/gen.json')).json();
      const renderer = await fetch('canvaskit/chromium/canvaskit.wasm');
      const font = await fetch('assets/assets/fonts/Roboto-Regular.ttf');
      const serif = await fetch('assets/assets/fonts/Newsreader.ttf');
      const sans = await fetch('assets/assets/fonts/PlusJakartaSans.ttf');
      const bootstrap = await fetch('flutter_bootstrap.js');
      const shell = await (await fetch('index.html')).text();
      return {web:web.chapters['1'][0].t, tagalog:tagalog.chapters['1'][0].t,
        mapping:mapping.schema_version, quiz:Array.isArray(quiz.chapters['1']) && quiz.chapters['1'].length > 0,
        renderer:renderer.ok, font:font.ok,
        serif:serif.ok && (await serif.arrayBuffer()).byteLength > 0,
        sans:sans.ok && (await sans.arrayBuffer()).byteLength > 0, bootstrap:bootstrap.ok,
        shell:shell.includes('flutter_bootstrap.js') && shell.includes('NEXT_PWA_RELEASE')};
    })()`);
    assert.equal(offline.web, 'In the beginning, God created the heavens and the earth.');
    assert.equal(offline.tagalog, 'Nang pasimula ay nilikha ng Dios ang langit at ang lupa.');
    assert.equal(offline.mapping, 2); assert(offline.quiz); assert(offline.renderer); assert(offline.font);
    assert(offline.serif); assert(offline.sans); assert(offline.bootstrap); assert(offline.shell);
    const result = {browser:'headless Chromium', httpCacheDisabled:true, networkOffline:true,
      staticCacheFiles:ready.files, releaseA, releaseB,
      passed:['legacy migration without reload','waiting update banner','user-consented reload','old cache cleanup',
        'network-first shell','unvisited WEB book','unvisited Tagalog book','mapping','local quiz','local renderer','Roboto font',
        'Newsreader font','Plus Jakarta Sans font','bootstrap','app shell']};
    fs.writeFileSync('build/reader_size/offline_browser_check.json', JSON.stringify(result, null, 2) + '\n');
    console.log('PASS: legacy migration, consent update, cache cleanup and full offline assets (' + ready.files + ' cached files).');
  } finally {
    if (send) {try {await send('Browser.close');} catch {}}
    if (socket) socket.close();
    chrome.kill();
    server.closeAllConnections(); server.close();
  }
}
main().catch((error) => {console.error(error.message); process.exitCode = 1;});
