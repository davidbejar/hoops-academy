import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_channel.dart';

final updateChannelProvider = Provider<UpdateChannel>((ref) => createUpdateChannel());

/// True once a new build is waiting to be activated.
class UpdateAvailable extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref.watch(updateChannelProvider).updateReady.listen((_) => state = true);
    ref.onDispose(sub.cancel);
    return false;
  }

  void reload() => ref.read(updateChannelProvider).activate();
}

final updateAvailableProvider = NotifierProvider<UpdateAvailable, bool>(UpdateAvailable.new);
