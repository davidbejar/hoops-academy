import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../storage/preferences.dart';

const _prefKey = 'hoops.themeMode';

/// The user's choice of look (persisted in the browser, like the language):
/// light, dark, or the operating system's setting. An unknown or missing
/// stored value means [ThemeMode.system].
class ThemeModePreference extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_prefKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_prefKey, mode.name);
  }
}

final themeModePreferenceProvider =
    NotifierProvider<ThemeModePreference, ThemeMode>(ThemeModePreference.new);

/// The name of [mode] for Keycloak's sign-in page (`loginThemeParameter`).
/// `system` is sent too: the page then forgets an earlier explicit choice.
String loginThemeOf(ThemeMode mode) => mode.name;
