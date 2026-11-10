import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/navigation/destination_labels.dart';
import 'package:hoops_app/core/navigation/destinations.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

/// Five bottom-bar destinations share 360 px: 72 px each, and a 12 px label
/// is about 7 px per letter wide, so a label of more than ten letters wraps
/// over two lines ("Pertandingan" did). Widget tests draw with a font whose
/// letters are all 12 px wide, so the width is checked on the text instead.
void main() {
  const maxLetters = 10;
  // Admin and the application admin have the most destinations (five);
  // parents and players have fewer, wider slots.
  final widest = [
    ...destinationsFor(roles: {TenantRole.admin}, applicationAdmin: false),
    ...destinationsFor(roles: const {}, applicationAdmin: true),
  ];
  for (final locale in AppLocalizations.supportedLocales) {
    test(
      'bottom navigation labels fit one line at 360 px (${locale.languageCode})',
      () async {
        final l = await AppLocalizations.delegate.load(locale);
        for (final d in widest) {
          expect(
            d.label(l).length,
            lessThanOrEqualTo(maxLetters),
            reason: '"${d.label(l)}" would wrap in the 72 px bar slot',
          );
        }
      },
    );
  }
}
