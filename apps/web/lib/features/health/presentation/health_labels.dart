import '../../../core/api/athlete_api.dart' as ath;
import '../../../l10n/gen/app_localizations.dart';

/// Ordered POOR .. EXCELLENT.
const normBands = [
  ath.NormBand.POOR,
  ath.NormBand.BELOW_AVERAGE,
  ath.NormBand.AVERAGE,
  ath.NormBand.ABOVE_AVERAGE,
  ath.NormBand.EXCELLENT,
];

int bandIndex(ath.NormBand b) {
  final i = normBands.indexOf(b);
  return i < 0 ? 2 : i;
}

extension NormBandLabel on ath.NormBand {
  String label(AppLocalizations l) => switch (this) {
    ath.NormBand.POOR => l.bandPoor,
    ath.NormBand.BELOW_AVERAGE => l.bandBelowAverage,
    ath.NormBand.AVERAGE => l.bandAverage,
    ath.NormBand.ABOVE_AVERAGE => l.bandAboveAverage,
    _ => l.bandExcellent,
  };
}

extension InjurySeverityLabel on ath.InjurySeverity {
  String label(AppLocalizations l) => switch (this) {
    ath.InjurySeverity.MINOR => l.severityMinor,
    ath.InjurySeverity.MODERATE => l.severityModerate,
    _ => l.severitySevere,
  };
}
