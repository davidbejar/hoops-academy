{{flutter_js}}
{{flutter_build_config}}

// No `serviceWorkerSettings`: Flutter's own (deprecated, self-unregistering)
// worker must not fight with web/sw.js, which index.html registers.
_flutter.loader.load();
