import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tenant/application/tenant_providers.dart';
import '../storage/preferences.dart';

const supportedLanguageCodes = ['es', 'en', 'id'];
const _prefKey = 'hoops.locale';

/// The user's explicit language choice (persisted in the browser), or null.
class LocalePreference extends Notifier<String?> {
  @override
  String? build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_prefKey);
    return supportedLanguageCodes.contains(stored) ? stored : null;
  }

  Future<void> set(String languageCode) async {
    assert(supportedLanguageCodes.contains(languageCode));
    state = languageCode;
    await ref.read(sharedPreferencesProvider).setString(_prefKey, languageCode);
  }
}

final localePreferenceProvider = NotifierProvider<LocalePreference, String?>(
  LocalePreference.new,
);

/// Explicit choice, else the academy's `defaultLocale`, else Spanish.
final effectiveLocaleProvider = Provider<Locale>((ref) {
  final chosen = ref.watch(localePreferenceProvider);
  final tenantDefault = ref.watch(tenantProfileProvider).value?.defaultLocaleCode;
  final code = chosen ?? tenantDefault;
  return Locale(supportedLanguageCodes.contains(code) ? code! : 'es');
});
