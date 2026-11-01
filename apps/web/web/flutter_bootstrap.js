{{flutter_js}}
{{flutter_build_config}}

// No `serviceWorkerSettings`: Flutter's own (deprecated, self-unregistering)
// worker must not fight with web/sw.js, which index.html registers.
//
// Everything is served by this origin (build with --no-web-resources-cdn, see
// tool/build_web.sh): CanvasKit comes from build/web/canvaskit (the generated
// build config sets useLocalCanvasKit) and Roboto from assets/fonts/fallback.
// The engine's default font-fallback host is Google's CDN; point it at ourselves so
// a glyph outside Roboto can never trigger a third-party request.
_flutter.loader.load({
  config: { fontFallbackBaseUrl: 'assets/fonts/' },
});
