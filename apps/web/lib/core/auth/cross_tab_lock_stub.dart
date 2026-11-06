import 'dart:async';

final _tails = <String, Future<void>>{};

/// Runs [body] once every earlier holder of [name] in this isolate is done.
Future<void> withCrossTabLock(String name, Future<void> Function() body) {
  final previous = _tails[name] ?? Future<void>.value();
  final done = previous.then((_) => body()).catchError((Object _) {});
  _tails[name] = done;
  return done;
}
