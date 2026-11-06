/// Navigates the browser to the IdP end-session URL (web); a no-op elsewhere
/// (tests, native tooling).
library;

export 'end_session_redirect_stub.dart'
    if (dart.library.js_interop) 'end_session_redirect_web.dart';
