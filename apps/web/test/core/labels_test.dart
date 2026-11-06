import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/labels.dart';
import 'package:hoops_app/l10n/gen/app_localizations_en.dart';
import 'package:hoops_app/l10n/gen/app_localizations_es.dart';
import 'package:hoops_app/l10n/gen/app_localizations_id.dart';
import 'package:hoops_core_api/hoops_core_api.dart' as api;

void main() {
  test('every PlayerStatus has its own label, REJECTED is not "withdrawn"', () {
    final real = [
      for (final s in api.PlayerStatus.values)
        if (s != api.PlayerStatus.unknownDefaultOpenApi) s,
    ];
    for (final l in [
      AppLocalizationsEs(),
      AppLocalizationsEn(),
      AppLocalizationsId(),
    ]) {
      final labels = {for (final s in real) s: s.label(l)};
      expect(labels.values.toSet().length, real.length, reason: '$labels');
    }
    expect(api.PlayerStatus.REJECTED.label(AppLocalizationsEs()), 'Rechazado');
    expect(api.PlayerStatus.REJECTED.label(AppLocalizationsEn()), 'Rejected');
    expect(api.PlayerStatus.REJECTED.label(AppLocalizationsId()), 'Ditolak');
  });
}
