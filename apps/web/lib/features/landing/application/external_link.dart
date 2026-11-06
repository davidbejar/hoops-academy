import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'external_link_stub.dart'
    if (dart.library.js_interop) 'external_link_web.dart';

/// Opens a page outside the app (the landing's GitHub link). A port so tests
/// record the URL instead of leaving the page.
abstract interface class ExternalLinkOpener {
  void open(Uri url);
}

class _BrowserLinkOpener implements ExternalLinkOpener {
  const _BrowserLinkOpener();

  @override
  void open(Uri url) => openInNewTab(url);
}

final externalLinkOpenerProvider = Provider<ExternalLinkOpener>(
  (ref) => const _BrowserLinkOpener(),
);
