// Real Chromium check: Cache API only, an unvisited book, renderer and app shell.
// Run after flutter build web: node tools/check_reader_offline.cjs
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {spawn} = require('node:child_process');
const assert = require('node:assert/strict');

async function main() {
  const root = path.resolve('build/web');
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
      response.writeHead(200, {'Content-Type':'text/html'});
      return response.end('<!doctype html><title>Reader offline check</title>');
    }
    const file = path.resolve(root, '.' + (name === '/' ? '/index.html' : decodeURIComponent(name)));
    if (!file.startsWith(root + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
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
    console.log('Preparing the release app static cache in a fresh headless browser…');
    const ready = await evaluate(`(async () => {
      await navigator.serviceWorker.register('/reader_service_worker.js', {updateViaCache:'none'});
      await navigator.serviceWorker.ready;
      if (!navigator.serviceWorker.controller) await new Promise(resolve => navigator.serviceWorker.addEventListener('controllerchange', resolve, {once:true}));
      const names = await caches.keys();
      const cache = await caches.open(names.find(name => name.startsWith('bible-track-reader-')));
      return {controlled:!!navigator.serviceWorker.controller, files:(await cache.keys()).length};
    })()`);
    assert(ready.controlled);
    await send('Network.emulateNetworkConditions', {offline:true, latency:0, downloadThroughput:0, uploadThroughput:0});
    const offline = await evaluate(`(async () => {
      const web = await (await fetch('assets/assets/bible/web/gen.json')).json();
      const tagalog = await (await fetch('assets/assets/bible/tl1905/gen.json')).json();
      const mapping = await (await fetch('assets/assets/bible/mapping.json')).json();
      const renderer = await fetch('canvaskit/chromium/canvaskit.wasm');
      const shell = await (await fetch('index.html')).text();
      return {web:web.chapters['1'][0].t, tagalog:tagalog.chapters['1'][0].t,
        mapping:mapping.schema_version, renderer:renderer.ok, shell:shell.includes('flutter_bootstrap.js')};
    })()`);
    assert.equal(offline.web, 'In the beginning, God created the heavens and the earth.');
    assert.equal(offline.tagalog, 'Nang pasimula ay nilikha ng Dios ang langit at ang lupa.');
    assert.equal(offline.mapping, 2); assert(offline.renderer); assert(offline.shell);
    const result = {browser:'headless Chromium', httpCacheDisabled:true, networkOffline:true,
      staticCacheFiles:ready.files, passed:['unvisited WEB book','unvisited Tagalog book','mapping','local renderer','app shell']};
    fs.writeFileSync('build/reader_size/offline_browser_check.json', JSON.stringify(result, null, 2) + '\n');
    console.log('PASS: offline books, mapping, renderer and shell served by the service worker (' + ready.files + ' cached files).');
  } finally {
    if (send) {try {await send('Browser.close');} catch {}}
    if (socket) socket.close();
    chrome.kill();
    server.closeAllConnections(); server.close();
  }
}
main().catch((error) => {console.error(error.message); process.exitCode = 1;});
