import 'dart:js_interop';

extension type _Location(JSObject _) implements JSObject {
  external void assign(String url);
}

@JS('window.location')
external _Location get _location;

void redirectBrowserTo(Uri url) => _location.assign(url.toString());
