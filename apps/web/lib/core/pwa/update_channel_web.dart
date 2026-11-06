import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'update_channel.dart';

/// Browser implementation over `navigator.serviceWorker`. `index.html`
/// registers `sw.js`; this only observes the registration.
class ServiceWorkerUpdateChannel implements UpdateChannel {
  ServiceWorkerUpdateChannel() {
    unawaited(_watch());
  }

  final _ready = StreamController<void>.broadcast();
  web.ServiceWorker? _waiting;
  bool _reloading = false;

  @override
  Stream<void> get updateReady => _ready.stream;

  Future<void> _watch() async {
    final container = web.window.navigator.serviceWorker;
    try {
      // `ready` resolves once a worker is active; null-safe on unsupported browsers.
      final reg = await container.ready.toDart;
      // Without a controller this is the first install: nothing to replace.
      if (container.controller == null) return;
      void waiting(web.ServiceWorker? w) {
        if (w == null) return;
        _waiting = w;
        _ready.add(null);
      }

      waiting(reg.waiting);
      reg.addEventListener(
        'updatefound',
        ((web.Event _) {
          final installing = reg.installing;
          installing?.addEventListener(
            'statechange',
            ((web.Event _) {
              if (installing.state == 'installed')
                waiting(reg.waiting ?? installing);
            }).toJS,
          );
        }).toJS,
      );
      container.addEventListener(
        'controllerchange',
        ((web.Event _) {
          if (_reloading) return;
          _reloading = true;
          web.window.location.reload();
        }).toJS,
      );
      Timer.periodic(const Duration(hours: 1), (_) => reg.update());
    } on Object {
      // No service worker support: no updates to announce.
    }
  }

  @override
  void activate() {
    final w = _waiting;
    if (w == null) return;
    final message = JSObject()..['type'] = 'SKIP_WAITING'.toJS;
    w.postMessage(message);
  }
}

UpdateChannel createUpdateChannel() => ServiceWorkerUpdateChannel();
