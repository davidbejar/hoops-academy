/// Reloads the page after the demo data was reset, so every screen starts from the seed again.
library;

export 'mock_reload_stub.dart'
    if (dart.library.js_interop) 'mock_reload_web.dart';
