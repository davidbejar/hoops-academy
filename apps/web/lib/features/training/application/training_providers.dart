import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../roster/application/roster_providers.dart';
import '../data/plans_repository.dart';
import '../data/training_repository.dart';
import '../domain/week.dart';

// ---------------------------------------------------------------- repositories

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => ApiTrainingRepository(ref.watch(ath.athleteApiProvider), ref.watch(api.tenantIdProvider)),
);
final plansRepositoryProvider = Provider<PlansRepository>(
  (ref) => ApiPlansRepository(ref.watch(ath.athleteApiProvider), ref.watch(api.tenantIdProvider)),
);

ath.Date toAthDate(DateTime d) => ath.Date(d.year, d.month, d.day);

/// Team name for chips; null while unknown (parents may not read teams).
final teamNamesProvider = Provider<Map<String, String>>((ref) {
  final teams = ref.watch(teamsProvider).value ?? const <api.Team>[];
  return {for (final t in teams) t.id: t.name};
});

// ------------------------------------------------------------------- calendar

/// The wall clock. Overridden in tests (goldens) so "today" does not depend on the day the test runs.
final nowProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Monday of the week on screen.
class WeekStart extends Notifier<DateTime> {
  @override
  DateTime build() => startOfWeek(ref.read(nowProvider)());
  void shift(int weeks) => state = addWeeks(state, weeks);
  void today() => state = startOfWeek(ref.read(nowProvider)());
  void set(DateTime monday) => state = startOfWeek(monday);
}

final weekStartProvider = NotifierProvider<WeekStart, DateTime>(WeekStart.new);

/// Team filter of the calendar; null = all teams the caller can see.
class TeamFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final calendarTeamProvider = NotifierProvider<TeamFilter, String?>(TeamFilter.new);

class WeekSessionsNotifier extends AsyncNotifier<List<ath.TrainingSession>> {
  @override
  Future<List<ath.TrainingSession>> build() async {
    final monday = ref.watch(weekStartProvider);
    final team = ref.watch(calendarTeamProvider);
    final caps = ref.watch(capabilitiesProvider);
    final repo = ref.watch(trainingRepositoryProvider);
    final from = toAthDate(monday);
    final to = toAthDate(addWeeks(monday, 1).subtract(const Duration(days: 1)));
    List<ath.TrainingSession> all;
    if (team != null) {
      all = await repo.sessions(teamId: team, from: from, to: to);
    } else if (!caps.isAdmin && caps.staffTeamIds.isNotEmpty) {
      // Staff of specific teams: their teams only.
      final lists = await Future.wait([for (final t in caps.staffTeamIds) repo.sessions(teamId: t, from: from, to: to)]);
      all = [for (final l in lists) ...l];
    } else {
      all = await repo.sessions(from: from, to: to);
    }
    all.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return all;
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> create({
    required String teamId,
    required DateTime startsAt,
    required int durationMinutes,
    String? location,
    String? planId,
    String? notes,
  }) async {
    await ref.read(trainingRepositoryProvider).createSession(
      ath.CreateTrainingSessionRequest((b) => b
        ..teamId = teamId
        ..startsAt = startsAt.toUtc()
        ..durationMinutes = durationMinutes
        ..location = location
        ..planId = planId
        ..notes = notes),
    );
    await reload();
  }
}

final weekSessionsProvider = AsyncNotifierProvider<WeekSessionsNotifier, List<ath.TrainingSession>>(WeekSessionsNotifier.new);

// -------------------------------------------------------------------- session

/// A session with its attendance sheet (staff) and the team roster that
/// names the entries.
class SessionDetail {
  const SessionDetail({required this.session, this.attendance, this.roster = const []});
  final ath.TrainingSession session;
  final ath.SessionAttendance? attendance;
  final List<api.TeamPlayer> roster;
}

class SessionDetailNotifier extends AsyncNotifier<SessionDetail> {
  SessionDetailNotifier(this.sessionId);
  final String sessionId;

  @override
  Future<SessionDetail> build() async {
    final repo = ref.watch(trainingRepositoryProvider);
    final caps = ref.watch(capabilitiesProvider);
    final session = await repo.session(sessionId);
    if (!caps.canManageTraining(session.teamId)) return SessionDetail(session: session);
    final r = await Future.wait([
      repo.attendance(sessionId),
      ref.watch(teamsRepositoryProvider).roster(session.teamId),
    ]);
    return SessionDetail(
      session: session,
      attendance: r[0] as ath.SessionAttendance,
      roster: (r[1] as List<api.TeamPlayer>),
    );
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(weekSessionsProvider);
  }

  Future<void> cancel(String reason) async {
    await ref.read(trainingRepositoryProvider).cancelSession(sessionId, reason);
    await _reload();
  }

  Future<void> edit({DateTime? startsAt, int? durationMinutes, String? location, String? planId, String? notes}) async {
    await ref.read(trainingRepositoryProvider).updateSession(
      sessionId,
      ath.UpdateTrainingSessionRequest((b) => b
        ..startsAt = startsAt?.toUtc()
        ..durationMinutes = durationMinutes
        ..location = location
        ..planId = planId
        ..notes = notes),
    );
    await _reload();
  }

  Future<void> saveAttendance(List<ath.AttendanceInput> entries) async {
    await ref.read(trainingRepositoryProvider).recordAttendance(sessionId, entries);
    await _reload();
  }
}

final sessionDetailProvider = AsyncNotifierProvider.family<SessionDetailNotifier, SessionDetail, String>(
  SessionDetailNotifier.new,
);

// ------------------------------------------------------------------ schedules

class SchedulesNotifier extends AsyncNotifier<List<ath.TrainingSchedule>> {
  @override
  Future<List<ath.TrainingSchedule>> build() => ref.watch(trainingRepositoryProvider).schedules();

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(weekSessionsProvider);
  }

  Future<void> save({
    String? scheduleId,
    required String teamId,
    required ath.DayOfWeek day,
    required String startTime,
    required int durationMinutes,
    String? location,
    required DateTime validFrom,
    DateTime? validUntil,
  }) async {
    final repo = ref.read(trainingRepositoryProvider);
    if (scheduleId == null) {
      await repo.createSchedule(ath.TrainingScheduleInput((b) => b
        ..teamId = teamId
        ..dayOfWeek = day
        ..startTime = startTime
        ..durationMinutes = durationMinutes
        ..location = location
        ..validFrom = toAthDate(validFrom)
        ..validUntil = validUntil == null ? null : toAthDate(validUntil)));
    } else {
      await repo.updateSchedule(
        scheduleId,
        ath.UpdateTrainingScheduleRequest((b) => b
          ..dayOfWeek = day
          ..startTime = startTime
          ..durationMinutes = durationMinutes
          ..location = location
          ..validFrom = toAthDate(validFrom)
          ..validUntil = validUntil == null ? null : toAthDate(validUntil)),
      );
    }
    await _reload();
  }

  Future<void> delete(String scheduleId) async {
    await ref.read(trainingRepositoryProvider).deleteSchedule(scheduleId);
    await _reload();
  }
}

final schedulesProvider = AsyncNotifierProvider<SchedulesNotifier, List<ath.TrainingSchedule>>(SchedulesNotifier.new);

// ------------------------------------------------------------------- absences

class AbsencesNotifier extends AsyncNotifier<List<ath.PlannedAbsence>> {
  @override
  Future<List<ath.PlannedAbsence>> build() async {
    final list = await ref.watch(trainingRepositoryProvider).absences();
    list.sort((a, b) => a.fromDate.compareTo(b.fromDate));
    return list;
  }

  Future<void> create({required String playerId, required DateTime from, required DateTime to, String? reason}) async {
    await ref.read(trainingRepositoryProvider).createAbsence(
      ath.PlannedAbsenceInput((b) => b
        ..playerId = playerId
        ..fromDate = toAthDate(from)
        ..toDate = toAthDate(to)
        ..reason = reason),
    );
    ref.invalidateSelf();
    await future;
    ref.invalidate(weekSessionsProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(trainingRepositoryProvider).deleteAbsence(id);
    ref.invalidateSelf();
    await future;
  }
}

final absencesProvider = AsyncNotifierProvider<AbsencesNotifier, List<ath.PlannedAbsence>>(AbsencesNotifier.new);

// ---------------------------------------------------------------------- plans

/// Free-text search of the plan library.
class PlanSearch extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final planSearchProvider = NotifierProvider<PlanSearch, String>(PlanSearch.new);

/// Plan library: `true` = templates, `false` = the academy's own plans.
class PlanLibraryNotifier extends AsyncNotifier<List<ath.TrainingPlanSummary>> {
  PlanLibraryNotifier(this.templates);
  final bool templates;

  @override
  Future<List<ath.TrainingPlanSummary>> build() {
    final q = ref.watch(planSearchProvider).trim();
    return ref.watch(plansRepositoryProvider).plans(templates: templates, query: q.isEmpty ? null : q);
  }

  /// Copy-on-use: returns the copy so the caller can open/assign it.
  Future<ath.TrainingPlan> copy(String planId, {String? name}) async {
    final copy = await ref.read(plansRepositoryProvider).copyPlan(planId, name: name);
    ref.invalidate(planLibraryProvider);
    return copy;
  }

  Future<ath.TrainingPlan> create(String name, {String? description}) async {
    final plan = await ref.read(plansRepositoryProvider).createPlan(
      ath.CreateTrainingPlanRequest((b) => b
        ..name = name
        ..description = description),
    );
    ref.invalidate(planLibraryProvider);
    return plan;
  }

  Future<void> delete(String planId) async {
    await ref.read(plansRepositoryProvider).deletePlan(planId);
    ref.invalidate(planLibraryProvider);
  }
}

final planLibraryProvider = AsyncNotifierProvider.family<PlanLibraryNotifier, List<ath.TrainingPlanSummary>, bool>(
  PlanLibraryNotifier.new,
);

class PlanDetailNotifier extends AsyncNotifier<ath.TrainingPlan> {
  PlanDetailNotifier(this.planId);
  final String planId;

  PlansRepository get _repo => ref.read(plansRepositoryProvider);

  @override
  Future<ath.TrainingPlan> build() => ref.watch(plansRepositoryProvider).plan(planId);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(planLibraryProvider);
  }

  Future<void> rename(String name, String? description) async {
    await _repo.updatePlan(
      planId,
      ath.UpdateTrainingPlanRequest((b) => b
        ..name = name
        ..description = description),
    );
    await _reload();
  }

  Future<void> addItem(ath.PlanItemInput input) async {
    await _repo.addItem(planId, input);
    await _reload();
  }

  Future<void> updateItem(String itemId, ath.UpdatePlanItemRequest request) async {
    await _repo.updateItem(planId, itemId, request);
    await _reload();
  }

  Future<void> deleteItem(String itemId) async {
    await _repo.deleteItem(planId, itemId);
    await _reload();
  }

  /// Moves the item at [from] to [to] (indexes in the current order).
  Future<void> move(int from, int to) async {
    final items = [...state.requireValue.items];
    final moved = items.removeAt(from);
    items.insert(to, moved);
    await _repo.reorder(planId, [for (final i in items) i.id]);
    await _reload();
  }
}

final planDetailProvider = AsyncNotifierProvider.family<PlanDetailNotifier, ath.TrainingPlan, String>(
  PlanDetailNotifier.new,
);

// ---------------------------------------------------------------- assignments

/// Assignments the caller can see (server-filtered) with their completions.
class AssignmentsView {
  const AssignmentsView({required this.assignments, required this.completions});
  final List<ath.PlanAssignment> assignments;
  final List<ath.PlanCompletion> completions;

  ath.PlanCompletion? completionOf(String assignmentId, String playerId) {
    for (final c in completions) {
      if (c.assignmentId == assignmentId && c.playerId == playerId) return c;
    }
    return null;
  }

  Map<ath.CompletionStatus, int> countsFor(String assignmentId) {
    final out = <ath.CompletionStatus, int>{};
    for (final c in completions) {
      if (c.assignmentId == assignmentId) out[c.status] = (out[c.status] ?? 0) + 1;
    }
    return out;
  }
}

/// Family argument: the player whose assignments are wanted (null = all the
/// caller can see, used by staff).
class AssignmentsNotifier extends AsyncNotifier<AssignmentsView> {
  AssignmentsNotifier(this.playerId);
  final String? playerId;

  @override
  Future<AssignmentsView> build() async {
    final repo = ref.watch(plansRepositoryProvider);
    final r = await Future.wait([repo.assignments(playerId: playerId), repo.completions(playerId: playerId)]);
    final assignments = [...(r[0] as List<ath.PlanAssignment>)]..sort((a, b) => a.dueOn.compareTo(b.dueOn));
    return AssignmentsView(assignments: assignments, completions: r[1] as List<ath.PlanCompletion>);
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> assign({
    required String planId,
    String? teamId,
    String? playerId,
    required DateTime dueOn,
    String? notes,
  }) async {
    await ref.read(plansRepositoryProvider).assign(
      ath.CreatePlanAssignmentRequest((b) => b
        ..planId = planId
        ..teamId = teamId
        ..playerId = playerId
        ..dueOn = toAthDate(dueOn)
        ..notes = notes),
    );
    ref.invalidate(assignmentsProvider);
  }

  Future<void> unassign(String assignmentId) async {
    await ref.read(plansRepositoryProvider).deleteAssignment(assignmentId);
    await _reload();
  }

  Future<void> record(String assignmentId, String playerId, ath.CompletionStatus status, {String? comment}) async {
    await ref.read(plansRepositoryProvider).record(assignmentId, playerId, status, comment: comment);
    ref.invalidate(assignmentsProvider);
  }
}

final assignmentsProvider = AsyncNotifierProvider.family<AssignmentsNotifier, AssignmentsView, String?>(
  AssignmentsNotifier.new,
);

// ------------------------------------------------------------------- upcoming

/// Sessions in the next two weeks for the teams of [playerId].
final upcomingSessionsProvider = FutureProvider.family<List<ath.TrainingSession>, String>((ref, playerId) async {
  final player = await ref.watch(playerDetailProvider(playerId).future);
  final repo = ref.watch(trainingRepositoryProvider);
  final now = DateTime.now();
  final from = toAthDate(now);
  final to = toAthDate(now.add(const Duration(days: 14)));
  final lists = await Future.wait([for (final t in player.teams) repo.sessions(teamId: t.team.id, from: from, to: to)]);
  final all = [
    for (final l in lists)
      for (final s in l)
        if (s.status != ath.TrainingSessionStatus.CANCELLED) s,
  ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return all;
});
