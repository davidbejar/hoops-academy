import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/finance/application/finance_providers.dart';
import 'package:hoops_app/features/health/application/health_providers.dart';
import 'package:hoops_app/features/match/application/live_match_controller.dart';
import 'package:hoops_app/features/platform/application/platform_providers.dart';
import 'package:hoops_app/features/roster/application/roster_providers.dart';
import 'package:hoops_app/features/training/application/training_providers.dart';

/// WEB-09: what a detail screen reads for one id is dropped when the screen
/// is left, so coming back shows fresh data and no key stays in memory.
void main() {
  test('per-id detail providers are auto-dispose', () {
    final autoDispose = <String, bool>{
      'dueDetail': dueDetailProvider('x').isAutoDispose,
      'seasonBalance': seasonBalanceProvider('x').isAutoDispose,
      'teamDueStatus': teamDueStatusProvider('x').isAutoDispose,
      'playerDues': playerDuesProvider('x').isAutoDispose,
      'tenantUsageHistory': tenantUsageHistoryProvider('x').isAutoDispose,
      'tenantDetail': tenantDetailProvider('x').isAutoDispose,
      'injuries': injuriesProvider('x').isAutoDispose,
      'measurements': measurementsProvider('x').isAutoDispose,
      'testResults': testResultsProvider('x').isAutoDispose,
      'teamDetail': teamDetailProvider('x').isAutoDispose,
      'playerDetail': playerDetailProvider('x').isAutoDispose,
      'sessionDetail': sessionDetailProvider('x').isAutoDispose,
      'planDetail': planDetailProvider('x').isAutoDispose,
      'liveMatch': liveMatchProvider('x').isAutoDispose,
    };
    expect({
      for (final e in autoDispose.entries)
        if (!e.value) e.key,
    }, isEmpty);
  });
}
