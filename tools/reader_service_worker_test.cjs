const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function worker({missing} = {}) {
  const scope = 'https://example.test/reader/';
  const handlers = {};
  const stores = new Map();
  const requests = [];
  let online = true;
  let claimed = 0;
  let skipped = 0;
  const keyOf = (r) => typeof r === 'string' ? r : r.url;
  const caches = {
    async open(name) {
      if (!stores.has(name)) stores.set(name, new Map());
      const values = stores.get(name);
      return {
        async put(request, response) { values.set(keyOf(request), response.clone()); },
        async match(request, options = {}) {
          let key = keyOf(request);
          if (options.ignoreSearch) key = key.split('?')[0];
          return values.get(key)?.clone();
        },
      };
    },
    async keys() { return [...stores.keys()]; },
    async delete(name) { return stores.delete(name); },
  };
  const context = vm.createContext({URL, Request, Response, Set, Promise, caches,
    self: {
      registration: {scope},
      addEventListener(name, callback) { handlers[name] = callback; },
      async skipWaiting() { skipped++; },
      clients: {async claim() { claimed++; }},
    },
    importScripts(name) {
      assert.equal(name, 'reader_offline_assets.js');
      context.self.READER_OFFLINE = {version: 'test', files: [
        'assets/assets/bible/mapping.json',
        'assets/assets/bible/web/gen.json',
        'assets/assets/bible/tl1905/gen.json',
      ]};
    },
    async fetch(request) {
      const url = keyOf(request);
      requests.push(url);
      if (!online) throw new Error('offline');
      if (missing && url.endsWith(missing)) return new Response('missing', {status: 404});
      if (url.endsWith('assets/FontManifest.json')) return Response.json([
        {family: 'MaterialIcons', fonts: [{asset: 'fonts/MaterialIcons-Regular.otf'}]},
      ]);
      return new Response('bundled: ' + url);
    },
  });
  vm.runInContext(fs.readFileSync('web/reader_service_worker.js', 'utf8'), context);
  return {
    stores, caches, requests, scope,
    get claimed() { return claimed; }, get skipped() { return skipped; },
    offline() { online = false; },
    async event(name) {
      let promise;
      handlers[name]({waitUntil(value) { promise = value; }});
      await promise;
    },
    fetch(path, {method = 'GET', mode = 'cors'} = {}) {
      let promise;
      handlers.fetch({request: {url: new URL(path, scope).href, method, mode},
        respondWith(value) { promise = value; }});
      return promise;
    },
  };
}

test('unvisited Bible books, renderer, fonts and shell work offline after install', async () => {
  const w = worker();
  await w.event('install');
  await w.event('activate');
  assert.equal(w.skipped, 1);
  assert.equal(w.claimed, 1);
  w.offline();
  for (const path of ['assets/assets/bible/web/gen.json', 'assets/assets/bible/tl1905/gen.json',
    'canvaskit/canvaskit.wasm', 'canvaskit/chromium/canvaskit.wasm', 'assets/fonts/MaterialIcons-Regular.otf']) {
    const response = await w.fetch(path);
    assert.equal(response.status, 200);
    assert.match(await response.text(), /bundled:/);
  }
  const shell = await w.fetch('./', {mode: 'navigate'});
  assert.match(await shell.text(), /index\.html/);
  assert(w.requests.every((url) => url.startsWith(w.scope)), 'subdirectory hosting stays within scope');
});

test('never intercepts Firebase, auth endpoints, other APIs or non-GET writes', async () => {
  const w = worker();
  assert.equal(w.fetch('https://firestore.googleapis.com/v1/documents'), undefined);
  assert.equal(w.fetch('/__/auth/handler', {mode: 'navigate'}), undefined);
  assert.equal(w.fetch('api/progress'), undefined);
  assert.equal(w.fetch('assets/assets/bible/web/gen.json', {method: 'POST'}), undefined);
});

test('failed precache does not claim a partial offline installation', async () => {
  const w = worker({missing: 'assets/assets/bible/web/gen.json'});
  await assert.rejects(w.event('install'), /Offline asset unavailable/);
  assert.equal(w.skipped, 0);
  assert.equal(w.claimed, 0);
});

test('activation cleans only old reader caches', async () => {
  const w = worker();
  await w.caches.open('bible-track-reader-old');
  await w.caches.open('unrelated-cache');
  await w.event('install');
  await w.event('activate');
  assert(!w.stores.has('bible-track-reader-old'));
  assert(w.stores.has('unrelated-cache'));
});

test('generated resource list contains every source book and mapping', () => {
  const context = vm.createContext({self: {}});
  vm.runInContext(fs.readFileSync('web/reader_offline_assets.js', 'utf8'), context);
  const files = context.self.READER_OFFLINE.files;
  for (const translation of ['web', 'tl1905']) {
    for (const name of fs.readdirSync('assets/bible/' + translation)) {
      assert(files.includes(`assets/assets/bible/${translation}/${name}`), name);
    }
  }
  assert(files.includes('assets/assets/bible/mapping.json'));
  assert(files.every((name) => !name.includes('data/source')), 'raw archives are never shipped');
});
