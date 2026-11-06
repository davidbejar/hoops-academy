import 'dart:js_interop';

@JS('window.open')
external JSAny? _open(String url, String target, String features);

/// New tab without access to this window (`noopener`, `noreferrer`).
void openInNewTab(Uri url) =>
    _open(url.toString(), '_blank', 'noopener,noreferrer');
