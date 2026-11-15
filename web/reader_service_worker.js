'use strict';

// Replaced in build/web AFTER compilation; never ship this null template.
const BUILD = /* PWA_BUILD_START */ null /* PWA_BUILD_END */;
const CACHE_PREFIX = 'bible-track-pwa-';
const LEGACY_PREFIX = 'bible-track-reader-';
const CACHE_NAME = CACHE_PREFIX + (BUILD ? BUILD.version : 'unbuilt');
const FILES = new Set(BUILD ? BUILD.files : []);
const absolute = path => new URL(path, self.registration.scope).href;

async function verifiedResponse(file) {
  const response = await fetch(new Request(absolute(file), {cache:'no-store'}));
  if (!response.ok) throw new Error('Offline asset unavailable: ' + file);
  const bytes = await response.clone().arrayBuffer();
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)),
    byte => byte.toString(16).padStart(2, '0')).join('');
  if (hash !== BUILD.resources[file]) throw new Error('Offline asset integrity mismatch: ' + file);
  return response;
}

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    if (!BUILD) throw new Error('Run node tools/build_pwa.cjs after flutter build web');
    const existing = await caches.keys();
    const migrateLegacy = Boolean(self.registration.active) &&
      existing.some(key => key.startsWith(LEGACY_PREFIX)) &&
      !existing.some(key => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME);
    const cache = await caches.open(CACHE_NAME);
    let cursor = 0;
    const workers = await Promise.allSettled(Array.from({length:6}, async () => {
      while (cursor < BUILD.files.length) {
        const file = BUILD.files[cursor++];
        await cache.put(absolute(file), await verifiedResponse(file));
      }
    }));
    const failed = workers.find(result => result.status === 'rejected');
    if (failed) {
      await caches.delete(CACHE_NAME);
      throw failed.reason;
    }
    // Old pages have no update button. Migrate once without asking them to
    // reload. Future releases wait for an explicit SKIP_WAITING message.
    if (migrateLegacy) await self.skipWaiting();
  })());
});

self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') event.waitUntil(self.skipWaiting());
  if (event.data?.type === 'GET_VERSION' && event.ports?.[0]) {
    event.ports[0].postMessage({version:BUILD?.version});
  }
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if ((key.startsWith(CACHE_PREFIX) || key.startsWith(LEGACY_PREFIX)) && key !== CACHE_NAME) {
        await caches.delete(key);
      }
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  const scope = new URL(self.registration.scope);
  if (request.method !== 'GET' || url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) return;
  const path = decodeURIComponent(url.pathname.slice(scope.pathname.length));
  // Never cache auth, Firebase, APIs or non-public requests.
  if (/^(?:api|__|auth|oauth)(?:\/|$)/.test(path)) return;
  const navigation = path === 'index.html' || request.mode === 'navigate';
  if (!navigation && !FILES.has(path)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    if (navigation) {
      try {
        const response = await fetch(new Request(request, {cache:'no-cache'}));
        if (response.ok) return response;
        return await cache.match(absolute('index.html')) || response;
      } catch (error) {
        const fallback = await cache.match(absolute('index.html'));
        if (fallback) return fallback;
        throw error;
      }
    }
    const cached = await cache.match(absolute(path));
    if (cached) return cached;
    const response = await verifiedResponse(path);
    await cache.put(absolute(path), response.clone());
    return response;
  })());
});
