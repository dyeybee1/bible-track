{{flutter_js}}
{{flutter_build_config}}

// pwa_update.js owns worker registration, update checks and the consent banner.
// Do not ask Flutter's deprecated service-worker loader to register a worker.

// Both CanvasKit variants are bundled and cached; rendering needs no CDN.
_flutter.loader.load({config: {canvasKitBaseUrl: new URL('canvaskit/', document.baseURI).href}});
