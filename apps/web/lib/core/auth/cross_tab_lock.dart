/// One holder at a time for a named lock, across the browser tabs of the app
/// (Web Locks API) on web; within this isolate elsewhere (tests, tooling).
library;

export 'cross_tab_lock_stub.dart'
    if (dart.library.js_interop) 'cross_tab_lock_web.dart';
