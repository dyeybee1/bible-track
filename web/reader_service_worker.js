'use strict';
importScripts('reader_offline_assets.js');

const CACHE_PREFIX = 'bible-track-reader-';
const CACHE_NAME = CACHE_PREFIX + self.READER_OFFLINE.version;
const CORE = [
  'index.html', 'flutter_bootstrap.js', 'flutter.js', 'main.dart.js',
  'manifest.json', 'favicon.png', 'reader_offline_assets.js',
  'icons/Icon-192.png', 'icons/Icon-512.png',
  'icons/Icon-maskable-192.png', 'icons/Icon-maskable-512.png',
  'assets/AssetManifest.bin', 'assets/AssetManifest.bin.json',
  'assets/FontManifest.json', 'assets/NOTICES',
  'assets/packages/material_ui/shaders/ink_sparkle.frag',
  'canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm',
];
const absolute = (path) => new URL(path, self.registration.scope).href;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    const fontsResponse = await fetch(new Request(absolute('assets/FontManifest.json'), {cache: 'reload'}));
    if (!fontsResponse.ok) throw new Error('Font manifest unavailable');
    const fonts = await fontsResponse.json();
    const files = [...new Set([
      ...CORE, ...self.READER_OFFLINE.files,
      ...fonts.flatMap((family) => family.fonts.map((font) => 'assets/' + font.asset)),
    ])];
    // Cache all books, even those never opened, before claiming offline support.
    // Six requests at a time keep first-install background work bounded.
    let cursor = 0;
    await Promise.all(Array.from({length: 6}, async () => {
      while (cursor < files.length) {
        const request = new Request(absolute(files[cursor++]), {cache: 'reload'});
        const response = await fetch(request);
        if (!response.ok) throw new Error('Offline asset unavailable: ' + request.url);
        await cache.put(request, response);
      }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  const scope = new URL(self.registration.scope);
  if (request.method !== 'GET' || url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) return;
  const path = url.pathname.slice(scope.pathname.length);
  const navigation = request.mode === 'navigate' && (path === '' || path === 'index.html');
  // Only public, bundled app files. Auth endpoints, Firestore and other APIs
  // never enter this cache, even when hosted on the same origin.
  if (!navigation && !CORE.includes(path) && !path.startsWith('assets/') && !path.startsWith('canvaskit/')) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(navigation ? absolute('index.html') : request, {ignoreSearch: true});
    if (cached) return cached;
    const response = await fetch(request);
    if (response.ok) await cache.put(request, response.clone());
    return response;
  })());
});
