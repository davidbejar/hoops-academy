import 'package:web/web.dart' as web;

/// `noopener` keeps the opened page from reaching back into the app.
void openInNewTab(Uri url) {
  web.window.open(url.toString(), '_blank', 'noopener,noreferrer');
}
