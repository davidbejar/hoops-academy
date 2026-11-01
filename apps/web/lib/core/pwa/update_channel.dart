/// Port over the service worker update mechanism (`web/sw.js`): the app only
/// knows "a new build is installed and waiting" and "activate it".
library;

export 'update_channel_stub.dart' if (dart.library.js_interop) 'update_channel_web.dart';

abstract class UpdateChannel {
  /// Emits when a new build finished installing next to the running one.
  Stream<void> get updateReady;

  /// Tells the waiting worker to take over (`{type: 'SKIP_WAITING'}`); the
  /// page reloads once it controls it.
  void activate();
}
