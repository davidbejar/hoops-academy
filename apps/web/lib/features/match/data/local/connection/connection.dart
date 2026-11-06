/// Opens the offline match database: sqlite3.wasm on the web (IndexedDB
/// persistence, no shared worker, no COOP/COEP), sqlite on native builds.
library;

export 'native_connection.dart'
    if (dart.library.js_interop) 'web_connection.dart';
