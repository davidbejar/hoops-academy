import 'update_channel.dart';

/// No service worker (tests, native tooling).
class NoUpdateChannel implements UpdateChannel {
  const NoUpdateChannel();

  @override
  Stream<void> get updateReady => const Stream.empty();

  @override
  void activate() {}
}

UpdateChannel createUpdateChannel() => const NoUpdateChannel();
