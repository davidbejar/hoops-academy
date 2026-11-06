import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/platform/presentation/tenant_detail_screen.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

/// Every counter the services (and the demo mock) report has a translated
/// label in all three locales; none falls back to the raw key (WP70 note).
void main() {
  const keys = [
    'trainingSchedules',
    'finishedMatches',
    'membersAdmin',
    'membersCoach',
  ];
  for (final code in ['es', 'en', 'id']) {
    test('counter labels are translated ($code)', () {
      final l = lookupAppLocalizations(Locale(code));
      for (final key in keys) {
        expect(usageCounterLabel(l, key), isNot(key), reason: '$code $key');
      }
    });
  }
}
