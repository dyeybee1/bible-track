'use strict';
(() => {
  function createPwaUpdater(env) {
    const {document, navigator} = env;
    const serviceWorker = navigator.serviceWorker;
    let registration, banner, message, button, timeout;
    let started = false, checking = false, requested = false, reloaded = false, needsReload = false;
    let previousController = serviceWorker?.controller;
    const language = () => /^(fil|tl)(-|$)/i.test(document.documentElement.lang) ? 'fil' : 'en';
    const strings = () => language() === 'fil'
      ? {message:'May bagong bersyon ng app', action:'I-update', applying:'Ina-update…', retry:'Hindi natuloy ang update. Subukan ulit.'}
      : {message:'A new version is available', action:'Update', applying:'Updating…', retry:'Update could not be applied. Try again.'};
    function render() {
      if (!banner) return;
      const text = strings();
      banner.lang = language();
      message.textContent = text.message;
      button.textContent = requested ? text.applying : text.action;
      button.disabled = requested;
    }
    function reloadOnce() {
      if (reloaded) return;
      reloaded = true;
      env.clearTimeout(timeout);
      env.location.reload();
    }
    function showBanner() {
      if (!banner) {
        const style = document.createElement('style');
        style.textContent = '#bt-pwa-update{position:fixed;z-index:2147483647;top:calc(env(safe-area-inset-top,0px) + 10px);left:12px;right:12px;max-width:480px;margin:auto;display:flex;align-items:center;gap:12px;padding:10px 12px 10px 16px;border:1px solid #ded3ed;border-radius:16px;background:#f4f2f6;color:#281044;box-shadow:0 4px 24px #160b2526;font:14px/1.4 Roboto,Arial,sans-serif}#bt-pwa-update span{flex:1;min-width:0}#bt-pwa-update button{border:0;border-radius:24px;padding:12px 18px;min-height:44px;background:#c3f53a;color:#281044;font:500 14px/1.3 Roboto,Arial,sans-serif;cursor:pointer}#bt-pwa-update button:disabled{opacity:.65;cursor:wait}#bt-pwa-update button:focus-visible{outline:2px solid #3f008d;outline-offset:3px}';
        document.head.appendChild(style);
        banner = document.createElement('section');
        banner.id = 'bt-pwa-update';
        banner.setAttribute('role', 'status');
        banner.setAttribute('aria-live', 'polite');
        message = document.createElement('span');
        button = document.createElement('button');
        button.type = 'button';
        button.addEventListener('click', applyUpdate);
        banner.appendChild(message);
        banner.appendChild(button);
        document.body.appendChild(banner);
      }
      render();
    }
    function applyUpdate() {
      if (requested) return;
      requested = true;
      render();
      // Activation in another tab never reloads this tab without consent.
      if (needsReload) { reloadOnce(); return; }
      const waiting = registration?.waiting;
      if (!waiting) { requested = false; render(); checkForUpdate(); return; }
      timeout = env.setTimeout(() => { requested = false; render(); message.textContent = strings().retry; }, 20000);
      waiting.postMessage({type:'SKIP_WAITING'});
    }
    function controllerChanged() {
      const current = serviceWorker.controller;
      if (requested) { reloadOnce(); return; }
      if (previousController && current !== previousController) { needsReload = true; showBanner(); }
      previousController = current;
    }
    function watchInstalling() {
      const installing = registration.installing;
      if (!installing) return;
      const changed = () => {
        if (installing.state === 'installed' && registration.waiting && serviceWorker.controller) showBanner();
      };
      installing.addEventListener('statechange', changed);
      changed();
    }
    async function checkForUpdate() {
      if (!registration || checking) return;
      checking = true;
      try { await registration.update(); if (registration.waiting) showBanner(); }
      catch (error) { env.console?.info('App update check will retry when online.', error); }
      finally { checking = false; }
    }
    async function start() {
      if (started || !serviceWorker) return;
      started = true;
      serviceWorker.addEventListener('controllerchange', controllerChanged);
      try {
        registration = await serviceWorker.register(new URL('reader_service_worker.js', document.baseURI),
          {scope:new URL('./', document.baseURI).pathname, updateViaCache:'none'});
        registration.addEventListener('updatefound', watchInstalling);
        watchInstalling();
        if (registration.waiting) showBanner();
        await checkForUpdate();
        document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible') checkForUpdate(); });
        env.setInterval(checkForUpdate, 30 * 60 * 1000);
        if (env.MutationObserver) new env.MutationObserver(render).observe(document.documentElement,
          {attributes:true, attributeFilter:['lang']});
      } catch (error) { started = false; env.console?.info('Offline preparation will retry on next visit.', error); }
    }
    return {start, checkForUpdate};
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = {createPwaUpdater};
  if (typeof window !== 'undefined') {
    window.bibleTrackPwa = createPwaUpdater(window);
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => window.bibleTrackPwa.start(), {once:true});
    else window.bibleTrackPwa.start();
  }
})();
