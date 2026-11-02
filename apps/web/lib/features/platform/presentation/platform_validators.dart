import '../../../l10n/gen/app_localizations.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Shared by the "new academy" and the administrator dialogs.
String? emailValidator(AppLocalizations l, String? v) => _emailPattern.hasMatch((v ?? '').trim()) ? null : l.fieldInvalidEmail;
