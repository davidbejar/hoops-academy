/// Opens a page outside the app (the identity provider's account console) in a new browser tab.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'external_link_stub.dart'
    if (dart.library.js_interop) 'external_link_web.dart';

/// The browser action behind "open in a new tab"; tests replace it to record the address.
final externalLinkOpenerProvider = Provider<void Function(Uri)>(
  (ref) => openInNewTab,
);
