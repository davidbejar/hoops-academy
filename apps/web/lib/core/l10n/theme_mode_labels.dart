import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// What the theme rows and the landing's theme menu show of a [ThemeMode].
extension ThemeModeLabel on ThemeMode {
  String label(AppLocalizations l) => switch (this) {
    ThemeMode.system => l.themeSystem,
    ThemeMode.light => l.themeLight,
    ThemeMode.dark => l.themeDark,
  };

  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}
