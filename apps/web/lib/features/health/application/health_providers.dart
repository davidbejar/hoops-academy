import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../training/application/training_providers.dart' show toAthDate;
import '../data/fitness_repository.dart';
import '../data/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => ApiHealthRepository(ref.watch(ath.athleteApiProvider), ref.watch(api.tenantIdProvider)),
);
final fitnessRepositoryProvider = Provider<FitnessRepository>(
  (ref) => ApiFitnessRepository(ref.watch(ath.athleteApiProvider), ref.watch(api.tenantIdProvider)),
);

// ------------------------------------------------------------------- injuries

class InjuriesNotifier extends AsyncNotifier<List<ath.Injury>> {
  InjuriesNotifier(this.playerId);
  final String playerId;

  @override
  Future<List<ath.Injury>> build() async {
    final list = await ref.watch(healthRepositoryProvider).injuries(playerId: playerId);
    list.sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    return list;
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(openInjuriesProvider);
  }

  Future<void> create({
    required DateTime occurredOn,
    required String bodyPart,
    required ath.InjurySeverity severity,
    String? description,
    DateTime? expectedReturnOn,
  }) async {
    await ref.read(healthRepositoryProvider).createInjury(
      ath.CreateInjuryRequest((b) => b
        ..playerId = playerId
        ..occurredOn = toAthDate(occurredOn)
        ..bodyPart = bodyPart
        ..severity = severity
        ..description = description
        ..expectedReturnOn = expectedReturnOn == null ? null : toAthDate(expectedReturnOn)),
    );
    await _reload();
  }

  Future<void> updateExpectedReturn(String injuryId, DateTime expectedReturnOn) async {
    await ref.read(healthRepositoryProvider).updateInjury(
      injuryId,
      ath.UpdateInjuryRequest((b) => b.expectedReturnOn = toAthDate(expectedReturnOn)),
    );
    await _reload();
  }

  Future<void> recover(String injuryId, DateTime actualReturnOn) async {
    await ref.read(healthRepositoryProvider).updateInjury(
      injuryId,
      ath.UpdateInjuryRequest((b) => b
        ..status = ath.InjuryStatus.RECOVERED
        ..actualReturnOn = toAthDate(actualReturnOn)),
    );
    await _reload();
  }
}

final injuriesProvider = AsyncNotifierProvider.family<InjuriesNotifier, List<ath.Injury>, String>(InjuriesNotifier.new);

/// Open injuries of everyone the caller can see: drives the availability badge.
final openInjuriesProvider = FutureProvider<Map<String, ath.Injury>>((ref) async {
  final list = await ref.watch(healthRepositoryProvider).injuries(status: ath.InjuryStatus.OPEN);
  return {for (final i in list) i.playerId: i};
});

// --------------------------------------------------------------- measurements

class MeasurementsNotifier extends AsyncNotifier<List<ath.BodyMeasurement>> {
  MeasurementsNotifier(this.playerId);
  final String playerId;

  @override
  Future<List<ath.BodyMeasurement>> build() async {
    final list = await ref.watch(healthRepositoryProvider).measurements(playerId);
    list.sort((a, b) => a.measuredOn.compareTo(b.measuredOn));
    return list;
  }

  Future<void> add({required DateTime measuredOn, double? heightCm, double? weightKg}) async {
    await ref.read(healthRepositoryProvider).createMeasurement(
      ath.BodyMeasurementInput((b) => b
        ..playerId = playerId
        ..measuredOn = toAthDate(measuredOn)
        ..heightCm = heightCm
        ..weightKg = weightKg),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(healthRepositoryProvider).deleteMeasurement(id);
    ref.invalidateSelf();
    await future;
  }
}

final measurementsProvider = AsyncNotifierProvider.family<MeasurementsNotifier, List<ath.BodyMeasurement>, String>(
  MeasurementsNotifier.new,
);

// ---------------------------------------------------------------- fitness tests

class TestTypesNotifier extends AsyncNotifier<List<ath.PhysicalTestType>> {
  @override
  Future<List<ath.PhysicalTestType>> build() => ref.watch(fitnessRepositoryProvider).types();

  Future<void> create({
    required String code,
    required String name,
    required String unit,
    required bool higherIsBetter,
    String? description,
  }) async {
    await ref.read(fitnessRepositoryProvider).createType(
      ath.$PhysicalTestTypeInput((b) => b
        ..code = code
        ..name = name
        ..unit = unit
        ..higherIsBetter = higherIsBetter
        ..description = description),
    );
    ref.invalidateSelf();
    await future;
  }
}

final testTypesProvider = AsyncNotifierProvider<TestTypesNotifier, List<ath.PhysicalTestType>>(TestTypesNotifier.new);

class TestResultsNotifier extends AsyncNotifier<List<ath.PhysicalTestResult>> {
  TestResultsNotifier(this.playerId);
  final String playerId;

  @override
  Future<List<ath.PhysicalTestResult>> build() async {
    final list = await ref.watch(fitnessRepositoryProvider).results(playerId: playerId);
    list.sort((a, b) => a.measuredOn.compareTo(b.measuredOn));
    return list;
  }

  /// Returns the stored result: it carries the expected band immediately.
  Future<ath.PhysicalTestResult> add({
    required String testTypeId,
    required DateTime measuredOn,
    required double value,
    String? notes,
  }) async {
    final r = await ref.read(fitnessRepositoryProvider).createResult(
      ath.PhysicalTestResultInput((b) => b
        ..playerId = playerId
        ..testTypeId = testTypeId
        ..measuredOn = toAthDate(measuredOn)
        ..value = value
        ..notes = notes),
    );
    ref.invalidateSelf();
    await future;
    return r;
  }

  Future<void> delete(String id) async {
    await ref.read(fitnessRepositoryProvider).deleteResult(id);
    ref.invalidateSelf();
    await future;
  }
}

final testResultsProvider = AsyncNotifierProvider.family<TestResultsNotifier, List<ath.PhysicalTestResult>, String>(
  TestResultsNotifier.new,
);

// ---------------------------------------------------------------------- norms

class NormFilter {
  const NormFilter({this.scope = 'EFFECTIVE', this.testTypeId});
  final String scope;
  final String? testTypeId;

  @override
  bool operator ==(Object other) => other is NormFilter && other.scope == scope && other.testTypeId == testTypeId;
  @override
  int get hashCode => Object.hash(scope, testTypeId);
}

class NormFilterNotifier extends Notifier<NormFilter> {
  @override
  NormFilter build() => const NormFilter();
  void set(NormFilter f) => state = f;
}

final normFilterProvider = NotifierProvider<NormFilterNotifier, NormFilter>(NormFilterNotifier.new);

class NormsNotifier extends AsyncNotifier<List<ath.PhysicalTestNorm>> {
  @override
  Future<List<ath.PhysicalTestNorm>> build() {
    final f = ref.watch(normFilterProvider);
    return ref.watch(fitnessRepositoryProvider).norms(testTypeId: f.testTypeId, scope: f.scope);
  }

  Future<void> save(ath.PhysicalTestNormInput input, {String? normId}) async {
    final repo = ref.read(fitnessRepositoryProvider);
    if (normId == null) {
      await repo.createNorm(input);
    } else {
      await repo.replaceNorm(normId, input);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(fitnessRepositoryProvider).deleteNorm(id);
    ref.invalidateSelf();
    await future;
  }
}

final normsProvider = AsyncNotifierProvider<NormsNotifier, List<ath.PhysicalTestNorm>>(NormsNotifier.new);
