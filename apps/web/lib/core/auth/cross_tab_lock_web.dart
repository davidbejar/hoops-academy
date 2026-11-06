import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'cross_tab_lock_stub.dart' as in_process;

/// Runs [body] while holding the exclusive Web Lock [name], which every tab of
/// this origin shares. Without the Web Locks API (old browser, insecure
/// context) the lock only covers this tab.
Future<void> withCrossTabLock(String name, Future<void> Function() body) {
  if (!web.window.navigator.has('locks')) {
    return in_process.withCrossTabLock(name, body);
  }
  JSPromise<JSAny?> granted(web.Lock? _) =>
      body().then<JSAny?>((_) => null, onError: (Object _) => null).toJS;
  return web.window.navigator.locks
      .request(name, granted.toJS)
      .toDart
      .then((_) {});
}
