{{flutter_js}}
{{flutter_build_config}}

// This SDK's generated worker only unregisters the legacy Flutter worker.
// Register our static-file worker without delaying normal app startup.
if ('serviceWorker' in navigator) {
  const prepareOffline = () => navigator.serviceWorker.register(
    new URL('reader_service_worker.js', document.baseURI),
    {scope: new URL('./', document.baseURI).pathname, updateViaCache: 'none'},
  ).catch((error) => console.info('Offline preparation will retry on next visit.', error));
  if (document.readyState === 'complete') prepareOffline();
  else window.addEventListener('load', prepareOffline, {once: true});
}

// Both CanvasKit variants are bundled and cached; rendering needs no CDN.
_flutter.loader.load({config: {canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href}});
