'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const vm = require('node:vm');
const {createHash, webcrypto} = require('node:crypto');
const {buildPwa} = require('./build_pwa.cjs');
const {createPwaUpdater} = require('../web/pwa_update.js');
const hash = value => createHash('sha256').update(value).digest('hex');
const template = fs.readFileSync('web/reader_service_worker.js', 'utf8');

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bible-pwa-'));
  t.after(() => fs.rmSync(root, {recursive:true, force:true}));
  const contents = {
    'index.html':'<script src="flutter_bootstrap.js"></script>',
    'main.dart.js':'compiled app A', 'flutter_bootstrap.js':'bootstrap A',
    'flutter.js':'loader', 'pwa_update.js':'updates A',
    'manifest.json':'{}', 'assets/FontManifest.json':'[]',
    'assets/assets/bible/web/gen.json':'WEB book',
    'assets/assets/bible/tl1905/gen.json':'Tagalog book',
    'assets/assets/bible/mapping.json':'mapping',
    'assets/assets/questions/gen.json':'quiz',
    'assets/assets/fonts/Roboto-Regular.ttf':'font',
    'canvaskit/chromium/canvaskit.wasm':'renderer',
    'icons/Icon-192.png':'icon',
    'reader_service_worker.js':template, 'version.json':'{"version":"1.0.0"}'
  };
  for (const [name, data] of Object.entries(contents)) {
    fs.mkdirSync(path.dirname(path.join(root, name)), {recursive:true});
    fs.writeFileSync(path.join(root, name), data);
  }
  return root;
}

function worker({missing, corrupt, stores = new Map(), active = false} = {}) {
  const scope = 'https://example.test/reader/';
  const contents = {'index.html':'shell A', 'main.dart.js':'app A',
    'flutter_bootstrap.js':'bootstrap', 'pwa_update.js':'update UI',
    'assets/assets/bible/web/gen.json':'WEB', 'assets/assets/bible/tl1905/gen.json':'Tagalog',
    'assets/assets/bible/mapping.json':'mapping',
    'canvaskit/chromium/canvaskit.wasm':'renderer',
    'assets/assets/fonts/Roboto-Regular.ttf':'font'};
  const files = Object.keys(contents);
  const build = {version:'test-release', files, resources:Object.fromEntries(files.map(f => [f, hash(contents[f])]))};
  const handlers = {}, requests = [];
  let online = true, claimed = 0, skipped = 0, networkShell = 'shell B', status = 200;
  const keyOf = r => typeof r === 'string' ? r : r.url;
  class RequestMock {
    constructor(input, options = {}) {
      this.url = keyOf(input); this.method = input.method || 'GET';
      this.mode = input.mode || 'cors'; Object.assign(this, options);
    }
  }
  const caches = {
    async open(name) {
      if (!stores.has(name)) stores.set(name, new Map());
      const values = stores.get(name);
      return {
        async put(request, response) { values.set(keyOf(request), response.clone()); },
        async match(request) { return values.get(keyOf(request))?.clone(); }
      };
    },
    async keys() { return [...stores.keys()]; },
    async delete(name) { return stores.delete(name); }
  };
  const context = vm.createContext({URL, Request:RequestMock, Response, Set, Promise, caches, crypto:webcrypto, Uint8Array,
    self:{registration:{scope, active:active ? {} : null},
      addEventListener(name, callback) { handlers[name] = callback; },
      async skipWaiting() { skipped++; }, clients:{async claim() { claimed++; }}},
    async fetch(request) {
      const url = keyOf(request); requests.push({url, cache:request.cache});
      if (!online) throw new Error('offline');
      const file = url.slice(scope.length);
      if (file === missing) return new Response('missing', {status:404});
      if (request.mode === 'navigate' || (file === 'index.html' && request.cache !== 'no-store')) {
        return new Response(networkShell, {status});
      }
      return new Response(file === corrupt ? 'wrong deployment' : contents[file]);
    }
  });
  vm.runInContext(template.replace(/\/\* PWA_BUILD_START \*\/[\s\S]*?\/\* PWA_BUILD_END \*\//,
    '/* PWA_BUILD_START */ ' + JSON.stringify(build) + ' /* PWA_BUILD_END */'), context);
  return {
    stores, caches, requests, build,
    get claimed() { return claimed; }, get skipped() { return skipped; },
    offline() { online = false; }, online() { online = true; },
    setStatus(value) { status = value; }, setShell(value) { networkShell = value; },
    async event(name, data = {}) {
      const promises = [];
      handlers[name]({...data, waitUntil(value) { promises.push(value); }});
      await Promise.all(promises);
    },
    fetch(file, {method = 'GET', mode = 'cors'} = {}) {
      let promise;
      handlers.fetch({request:new RequestMock({url:new URL(file, scope).href, method, mode}),
        respondWith(value) { promise = value; }});
      return promise;
    }
  };
}

test('post-build version hashes every precached byte, including a main.dart.js-only change', t => {
  const root = fixture(t);
  let previous = buildPwa(root);
  assert.equal(buildPwa(root).version, previous.version, 'idempotent rerun');
  assert.equal(JSON.parse(fs.readFileSync(path.join(root, 'version.json'))).version, '1.0.0');
  for (const file of previous.files) {
    const target = path.join(root, file), bytes = fs.readFileSync(target);
    const oldWorker = fs.readFileSync(path.join(root, 'reader_service_worker.js'), 'utf8');
    fs.appendFileSync(target, 'changed');
    const next = buildPwa(root);
    assert.notEqual(next.version, previous.version, file);
    assert.notEqual(fs.readFileSync(path.join(root, 'reader_service_worker.js'), 'utf8'), oldWorker, 'worker bytes change: ' + file);
    fs.writeFileSync(target, bytes);
    previous = buildPwa(root);
  }
  assert.equal(buildPwa(root).version, previous.version);
  assert(previous.files.some(f => f.startsWith('canvaskit/')));
  assert(previous.files.some(f => f.includes('/questions/')));
});

test('worker behavior, file addition and deletion change the release hash', t => {
  const root = fixture(t);
  const initial = buildPwa(root).version;
  fs.appendFileSync(path.join(root, 'reader_service_worker.js'), '\n// behavior revision\n');
  const behavior = buildPwa(root).version;
  assert.notEqual(behavior, initial);
  fs.writeFileSync(path.join(root, 'extra.txt'), 'extra');
  assert.notEqual(buildPwa(root).version, behavior);
  fs.unlinkSync(path.join(root, 'extra.txt'));
  assert.equal(buildPwa(root).version, behavior);
});

test('builder uses only build output and fails closed before Flutter compilation', t => {
  const root = fixture(t);
  fs.unlinkSync(path.join(root, 'main.dart.js'));
  assert.throws(() => buildPwa(root), /Build Flutter web first/);
});

test('all books, fonts, renderers and shell work offline; installation waits for consent', async () => {
  const w = worker();
  await w.event('install'); await w.event('activate');
  assert.equal(w.skipped, 0); assert.equal(w.claimed, 1);
  assert(w.requests.every(r => r.cache === 'no-store'));
  w.offline();
  for (const file of w.build.files) assert.equal((await w.fetch(file)).status, 200, file);
  assert.equal(await (await w.fetch('./', {mode:'navigate'})).text(), 'shell A');
  assert.equal(await (await w.fetch('read/gen/1', {mode:'navigate'})).text(), 'shell A');
});

test('navigation and explicit index are network-first without overwriting the offline snapshot', async () => {
  const w = worker(); await w.event('install');
  for (const file of ['./', 'read/gen/1', 'index.html']) {
    assert.equal(await (await w.fetch(file, {mode:'navigate'})).text(), 'shell B');
  }
  assert.equal(await (await w.fetch('main.dart.js')).text(), 'app A', 'running release remains consistent');
  w.setStatus(503);
  assert.equal(await (await w.fetch('./', {mode:'navigate'})).text(), 'shell A');
  w.offline();
  assert.equal(await (await w.fetch('./', {mode:'navigate'})).text(), 'shell A');
});

test('activation removes old/new-version app caches and preserves unrelated storage', async () => {
  const w = worker();
  for (const name of ['bible-track-reader-old', 'bible-track-pwa-older', 'unrelated-cache']) await w.caches.open(name);
  await w.event('install'); await w.event('activate');
  assert.deepEqual([...w.stores.keys()].sort(), ['bible-track-pwa-test-release', 'unrelated-cache']);
});

test('legacy migration activates once without requiring an update UI in the old page', async () => {
  const w = worker({active:true});
  await w.caches.open('bible-track-reader-old');
  await w.event('install'); assert.equal(w.skipped, 1);
  const later = worker({active:true, stores:w.stores});
  await later.caches.open('bible-track-pwa-previous');
  await later.event('install'); assert.equal(later.skipped, 0);
});

test('SKIP_WAITING is explicit; unrelated messages do not activate a release', async () => {
  const w = worker(); await w.event('install');
  await w.event('message', {data:{type:'hello'}}); assert.equal(w.skipped, 0);
  await w.event('message', {data:{type:'SKIP_WAITING'}}); assert.equal(w.skipped, 1);
});

for (const fault of ['missing', 'corrupt']) test('failed ' + fault + ' precache is deleted and cannot activate', async () => {
  const w = worker({[fault]:'assets/assets/bible/web/gen.json'});
  await assert.rejects(w.event('install'), /Offline asset/);
  assert.equal(w.skipped, 0); assert.equal(w.claimed, 0);
  assert.equal(w.stores.has('bible-track-pwa-test-release'), false);
});

test('never intercepts external services, APIs, auth routes or writes', () => {
  const w = worker();
  for (const url of ['https://firestore.googleapis.com/v1/documents','/__/auth/handler','api/progress','auth/callback','assets/private.json','version.json','reader_service_worker.js']) {
    assert.equal(w.fetch(url), undefined, url);
  }
  assert.equal(w.fetch('api/progress', {mode:'navigate'}), undefined);
  assert.equal(w.fetch('main.dart.js', {method:'POST'}), undefined);
});

class Events {
  constructor() { this.events = new Map(); }
  addEventListener(name, callback) {
    const list = this.events.get(name) || []; list.push(callback); this.events.set(name, list);
  }
  dispatch(name) { for (const callback of this.events.get(name) || []) callback(); }
}
class Element extends Events {
  constructor(tag) { super(); this.tagName = tag; this.children = []; this.textContent = ''; }
  setAttribute(name, value) { this[name] = value; }
  appendChild(child) { this.children.push(child); }
  click() { if (!this.disabled) this.dispatch('click'); }
}
function page({waiting = true, controlled = true, lang = 'fil'} = {}) {
  const document = new Events();
  document.baseURI = 'https://example.test/reader/';
  document.documentElement = {lang}; document.visibilityState = 'visible';
  document.head = new Element('head'); document.body = new Element('body');
  document.createElement = tag => new Element(tag);
  const sw = new Events(), registration = new Events(), messages = [], intervals = [], timers = [];
  let updates = 0, reloads = 0, mutation, updateError = false;
  sw.controller = controlled ? {release:'A'} : null;
  registration.waiting = waiting ? {postMessage(value) { messages.push(value); }} : null;
  registration.update = async () => { updates++; if (updateError) throw new Error('offline'); };
  sw.register = async (url, options) => {
    assert.equal(url.href, document.baseURI + 'reader_service_worker.js');
    assert.equal(options.updateViaCache, 'none'); return registration;
  };
  const env = {document, navigator:{serviceWorker:sw}, console:{info() {}},
    location:{reload() { reloads++; }}, clearTimeout() {},
    setTimeout(fn) { timers.push(fn); return timers.length; },
    setInterval(fn, ms) { intervals.push({fn, ms}); },
    MutationObserver:class { constructor(fn) { mutation = fn; } observe() {} }
  };
  const updater = createPwaUpdater(env);
  return {updater, document, registration, sw, messages, intervals, timers,
    get updates() { return updates; }, get reloads() { return reloads; },
    get banner() { return document.body.children[0]; },
    get button() { return document.body.children[0]?.children[1]; },
    offline() { updateError = true; },
    language(value) { document.documentElement.lang = value; mutation(); }
  };
}
const flush = () => new Promise(resolve => setImmediate(resolve));

test('banner localizes, prompts for a waiting update, and reloads once after consent/controllerchange', async () => {
  const p = page(); await p.updater.start();
  assert.equal(p.banner.children[0].textContent, 'May bagong bersyon ng app');
  assert.equal(p.button.textContent, 'I-update');
  p.language('en');
  assert.equal(p.banner.children[0].textContent, 'A new version is available');
  assert.equal(p.button.textContent, 'Update');
  assert.equal(p.reloads, 0);
  p.button.click(); assert.deepEqual(p.messages, [{type:'SKIP_WAITING'}]); assert.equal(p.reloads, 0);
  assert(p.button.disabled);
  p.sw.controller = {release:'B'}; p.sw.dispatch('controllerchange'); p.sw.dispatch('controllerchange');
  assert.equal(p.reloads, 1);
});

test('startup, visibility resume and 30-minute checks update; hidden state and offline never reload', async () => {
  const p = page({waiting:false}); await p.updater.start();
  assert.equal(p.updates, 1);
  assert.equal(p.intervals[0].ms, 1800000);
  p.document.visibilityState = 'hidden'; p.document.dispatch('visibilitychange'); assert.equal(p.updates, 1);
  p.document.visibilityState = 'visible'; p.document.dispatch('visibilitychange'); await flush(); assert.equal(p.updates, 2);
  await p.intervals[0].fn(); assert.equal(p.updates, 3);
  p.offline(); await p.updater.checkForUpdate(); assert.equal(p.reloads, 0);
  await p.updater.start(); assert.equal(p.intervals.length, 1);
});

test('background activation never reloads an open quiz/reader or another tab', async () => {
  const p = page({waiting:false}); await p.updater.start();
  p.sw.controller = {release:'B'}; p.sw.dispatch('controllerchange');
  assert.equal(p.reloads, 0); assert(p.banner);
  p.button.click(); assert.equal(p.reloads, 1); assert.equal(p.messages.length, 0);
});

test('first installation claims control without a reload or an update banner', async () => {
  const p = page({waiting:false, controlled:false}); await p.updater.start();
  p.sw.controller = {release:'A'}; p.sw.dispatch('controllerchange');
  assert.equal(p.reloads, 0); assert.equal(p.banner, undefined);
});

test('updatefound watches installation; an activation timeout permits retry without reload', async () => {
  const p = page({waiting:false}); await p.updater.start();
  const installing = new Events(); installing.state = 'installing';
  p.registration.installing = installing; p.registration.dispatch('updatefound');
  p.registration.waiting = {postMessage(value) { p.messages.push(value); }};
  installing.state = 'installed'; installing.dispatch('statechange');
  assert(p.banner); p.button.click(); p.timers[0]();
  assert.equal(p.button.disabled, false); assert.equal(p.reloads, 0);
});

test('Vercel control files revalidate and SPA fallback preserves static filesystem precedence', () => {
  const config = JSON.parse(fs.readFileSync('vercel.json'));
  assert(config.headers.some(rule => rule.source === '/(.*)' && rule.headers.some(h => h.key === 'Cache-Control' && h.value === 'no-cache')));
  assert.deepEqual(config.rewrites, [{source:'/(.*)', destination:'/index.html'}]);
  assert.equal(config.installCommand, undefined); assert.equal(config.outputDirectory, undefined);
});
