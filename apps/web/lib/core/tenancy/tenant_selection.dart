import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences.dart';

const _prefKey = 'hoops.selectedTenantId';

/// The tenant id the user picked, persisted locally. Whether it is still a
/// valid membership is decided by the session provider.
class SelectedTenantId extends Notifier<String?> {
  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_prefKey);

  Future<void> select(String tenantId) async {
    state = tenantId;
    await ref.read(sharedPreferencesProvider).setString(_prefKey, tenantId);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_prefKey);
  }
}

final selectedTenantIdProvider = NotifierProvider<SelectedTenantId, String?>(
  SelectedTenantId.new,
);
