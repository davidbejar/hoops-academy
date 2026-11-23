import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What every mutating notifier does after a write: run its `build` again and
/// wait for the new state (WEB-11). Siblings that show the same data are
/// invalidated after `reload()`, by the notifier that knows them.
mixin Reloading<T> on AsyncNotifier<T> {
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}
