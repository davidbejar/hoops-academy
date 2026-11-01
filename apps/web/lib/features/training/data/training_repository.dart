import '../../../core/api/athlete_api.dart' as ath;

/// Schedules, sessions, attendance and planned absences of athlete-service.
/// Returns the generated models (WP12 decision).
abstract class TrainingRepository {
  Future<List<ath.TrainingSession>> sessions({String? teamId, required ath.Date from, required ath.Date to});
  Future<ath.TrainingSession> session(String sessionId);
  Future<ath.TrainingSession> createSession(ath.CreateTrainingSessionRequest request);
  Future<ath.TrainingSession> updateSession(String sessionId, ath.UpdateTrainingSessionRequest request);
  Future<ath.TrainingSession> cancelSession(String sessionId, String reason);

  Future<List<ath.TrainingSchedule>> schedules({String? teamId});
  Future<ath.TrainingSchedule> createSchedule(ath.TrainingScheduleInput input);
  Future<ath.TrainingSchedule> updateSchedule(String scheduleId, ath.UpdateTrainingScheduleRequest request);
  Future<void> deleteSchedule(String scheduleId);

  Future<ath.SessionAttendance> attendance(String sessionId);
  Future<ath.SessionAttendance> recordAttendance(String sessionId, List<ath.AttendanceInput> entries);

  Future<List<ath.PlannedAbsence>> absences({String? playerId, String? teamId, ath.Date? from, ath.Date? to});
  Future<ath.PlannedAbsence> createAbsence(ath.PlannedAbsenceInput input);
  Future<void> deleteAbsence(String absenceId);
}

class ApiTrainingRepository implements TrainingRepository {
  ApiTrainingRepository(ath.HoopsAthleteApi client, this._t)
    : _sessions = client.getTrainingSessionsApi(),
      _schedules = client.getTrainingSchedulesApi(),
      _attendance = client.getAttendanceApi(),
      _absences = client.getPlannedAbsencesApi();

  final ath.TrainingSessionsApi _sessions;
  final ath.TrainingSchedulesApi _schedules;
  final ath.AttendanceApi _attendance;
  final ath.PlannedAbsencesApi _absences;
  final String _t;

  @override
  Future<List<ath.TrainingSession>> sessions({String? teamId, required ath.Date from, required ath.Date to}) async =>
      (await _sessions.listTrainingSessions(xTenantId: _t, teamId: teamId, from: from, to: to, size: 200)).data!.items.toList();

  @override
  Future<ath.TrainingSession> session(String sessionId) async =>
      (await _sessions.getTrainingSession(xTenantId: _t, sessionId: sessionId)).data!;

  @override
  Future<ath.TrainingSession> createSession(ath.CreateTrainingSessionRequest request) async =>
      (await _sessions.createTrainingSession(xTenantId: _t, createTrainingSessionRequest: request)).data!;

  @override
  Future<ath.TrainingSession> updateSession(String sessionId, ath.UpdateTrainingSessionRequest request) async =>
      (await _sessions.updateTrainingSession(xTenantId: _t, sessionId: sessionId, updateTrainingSessionRequest: request)).data!;

  @override
  Future<ath.TrainingSession> cancelSession(String sessionId, String reason) async => (await _sessions.cancelTrainingSession(
    xTenantId: _t,
    sessionId: sessionId,
    cancelTrainingSessionRequest: ath.CancelTrainingSessionRequest((b) => b.reason = reason),
  )).data!;

  @override
  Future<List<ath.TrainingSchedule>> schedules({String? teamId}) async =>
      (await _schedules.listTrainingSchedules(xTenantId: _t, teamId: teamId)).data!.toList();

  @override
  Future<ath.TrainingSchedule> createSchedule(ath.TrainingScheduleInput input) async =>
      (await _schedules.createTrainingSchedule(xTenantId: _t, trainingScheduleInput: input)).data!;

  @override
  Future<ath.TrainingSchedule> updateSchedule(String scheduleId, ath.UpdateTrainingScheduleRequest request) async =>
      (await _schedules.updateTrainingSchedule(xTenantId: _t, scheduleId: scheduleId, updateTrainingScheduleRequest: request)).data!;

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await _schedules.deleteTrainingSchedule(xTenantId: _t, scheduleId: scheduleId);
  }

  @override
  Future<ath.SessionAttendance> attendance(String sessionId) async =>
      (await _attendance.getSessionAttendance(xTenantId: _t, sessionId: sessionId)).data!;

  @override
  Future<ath.SessionAttendance> recordAttendance(String sessionId, List<ath.AttendanceInput> entries) async =>
      (await _attendance.recordSessionAttendance(
        xTenantId: _t,
        sessionId: sessionId,
        recordAttendanceRequest: ath.RecordAttendanceRequest((b) => b.entries.replace(entries)),
      )).data!;

  @override
  Future<List<ath.PlannedAbsence>> absences({String? playerId, String? teamId, ath.Date? from, ath.Date? to}) async =>
      (await _absences.listPlannedAbsences(xTenantId: _t, playerId: playerId, teamId: teamId, from: from, to: to, size: 100))
          .data!
          .items
          .toList();

  @override
  Future<ath.PlannedAbsence> createAbsence(ath.PlannedAbsenceInput input) async =>
      (await _absences.createPlannedAbsence(xTenantId: _t, plannedAbsenceInput: input)).data!;

  @override
  Future<void> deleteAbsence(String absenceId) async {
    await _absences.deletePlannedAbsence(xTenantId: _t, absenceId: absenceId);
  }
}
