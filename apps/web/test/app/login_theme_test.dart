import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/l10n/theme_mode_controller.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

void main() {
  test('every choice of look has a name for the sign-in page', () {
    expect(loginThemeOf(ThemeMode.light), 'light');
    expect(loginThemeOf(ThemeMode.dark), 'dark');
    // Sent too, so the page forgets an earlier explicit choice.
    expect(loginThemeOf(ThemeMode.system), 'system');
  });
}
