{{flutter_js}}
{{flutter_build_config}}

// No `serviceWorkerSettings`: Flutter's own (deprecated, self-unregistering)
// worker must not fight with web/sw.js, which index.html registers.
//
// Release (tool/build_web.sh, --no-web-resources-cdn): everything is served by this
// origin. CanvasKit comes from build/web/canvaskit (the generated build config sets
// useLocalCanvasKit) and Roboto from assets/fonts/fallback. The engine's default
// font-fallback host is Google's CDN; point it at ourselves so a glyph outside
// Roboto can never trigger a third-party request.
//
// Only that build bundles Roboto. A debug `flutter run` (compileTarget dartdevc)
// bundles no font even with --no-web-resources-cdn: pointing it at ourselves makes
// Roboto and every Noto fallback 404 and no text renders, so debug runs keep the
// engine default (test/web/bootstrap_fonts_test.dart).
(function () {
  var cfg = _flutter.buildConfig || {};
  var debugBuild = (cfg.builds || []).some(function (b) { return b.compileTarget === 'dartdevc'; });
  var selfHostedFonts = cfg.useLocalCanvasKit === true && !debugBuild;
  _flutter.loader.load({
    config: selfHostedFonts ? { fontFallbackBaseUrl: 'assets/fonts/' } : {},
  });
})();
