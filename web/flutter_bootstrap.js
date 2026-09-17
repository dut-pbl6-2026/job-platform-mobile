// Flutter Web bootstrap loader
// Referenced by web/index.html per https://docs.flutter.dev/platform-integration/web/initialization
(function () {
  'use strict';
  if (typeof window !== 'undefined') {
    window.addEventListener('load', function () {
      if (window._flutter && window._flutter.loader) {
        window._flutter.loader.load({
          onEntrypointLoaded: async function (engineInitializer) {
            const appRunner = await engineInitializer.initializeEngine();
            await appRunner.runApp();
          }
        });
      }
    });
  }
})();
