/// The small helpers of the form fields (WEB-07): what a field must contain
/// ([requiredValidator], e-mail, decimals), how typed text is read back
/// ([parseDecimal], [blankToNull]) and how a measurement is written
/// ([formatMeasure]), so every form and list agrees.
library;

import '../../l10n/gen/app_localizations.dart';

String? requiredValidator(AppLocalizations l, String? v) =>
    (v ?? '').trim().isEmpty ? l.fieldRequired : null;

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A pragmatic shape check (local part, `@`, a dotted domain); the server
/// checks the rest.
bool isValidEmail(String value) => _email.hasMatch(value.trim());

/// An address is needed and must look like one.
String? emailValidator(AppLocalizations l, String? v) =>
    isValidEmail(v ?? '') ? null : l.fieldInvalidEmail;

/// Like [emailValidator], but a blank is fine.
String? optionalEmailValidator(AppLocalizations l, String? v) =>
    (v ?? '').trim().isEmpty ? null : emailValidator(l, v);

/// A number typed with a comma or a point (`149,5`); null when it is not one.
double? parseDecimal(String? v) =>
    double.tryParse((v ?? '').trim().replaceAll(',', '.'));

/// A number is needed.
String? decimalValidator(AppLocalizations l, String? v) =>
    parseDecimal(v) == null ? l.fieldInvalidNumber : null;

/// A blank is fine; otherwise a number, above zero when [positive].
String? optionalDecimalValidator(
  AppLocalizations l,
  String? v, {
  bool positive = false,
}) {
  if ((v ?? '').trim().isEmpty) return null;
  final n = parseDecimal(v);
  return n == null || (positive && n <= 0) ? l.fieldInvalidNumber : null;
}

/// The trimmed text, or null for a blank: what an optional field sends.
String? blankToNull(String? v) {
  final t = (v ?? '').trim();
  return t.isEmpty ? null : t;
}

/// A measurement (height, weight, a test value) as text: a whole number
/// without decimals, otherwise at most two and no trailing zero (`37.55`,
/// `12.5`). The lists, the charts and the edit fields all use it.
String formatMeasure(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final text = v.toStringAsFixed(2);
  return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
}
