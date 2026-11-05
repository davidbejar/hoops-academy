import '../../../core/time/tenant_zone.dart';
import 'package:flutter/material.dart';

import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/ui/page_scaffold.dart' show ChipTone;
import '../../../l10n/gen/app_localizations.dart';

const weekdays = [
  ath.DayOfWeek.MONDAY,
  ath.DayOfWeek.TUESDAY,
  ath.DayOfWeek.WEDNESDAY,
  ath.DayOfWeek.THURSDAY,
  ath.DayOfWeek.FRIDAY,
  ath.DayOfWeek.SATURDAY,
  ath.DayOfWeek.SUNDAY,
];

/// `DateTime.weekday` (Monday = 1) to the contract enum.
ath.DayOfWeek dayOfWeekFor(int weekday) => weekdays[weekday - 1];

extension DayOfWeekLabel on ath.DayOfWeek {
  String label(AppLocalizations l) => switch (this) {
    ath.DayOfWeek.MONDAY => l.dayMonday,
    ath.DayOfWeek.TUESDAY => l.dayTuesday,
    ath.DayOfWeek.WEDNESDAY => l.dayWednesday,
    ath.DayOfWeek.THURSDAY => l.dayThursday,
    ath.DayOfWeek.FRIDAY => l.dayFriday,
    ath.DayOfWeek.SATURDAY => l.daySaturday,
    _ => l.daySunday,
  };
}

extension SessionStatusLabel on ath.TrainingSessionStatus {
  String label(AppLocalizations l) => switch (this) {
    ath.TrainingSessionStatus.PLANNED => l.sessionStatusPlanned,
    ath.TrainingSessionStatus.DONE => l.sessionStatusDone,
    _ => l.sessionStatusCancelled,
  };

  ChipTone get tone => switch (this) {
    ath.TrainingSessionStatus.PLANNED => ChipTone.neutral,
    ath.TrainingSessionStatus.DONE => ChipTone.good,
    _ => ChipTone.bad,
  };
}

extension AttendanceLabel on ath.AttendanceStatus {
  String label(AppLocalizations l) => switch (this) {
    ath.AttendanceStatus.PRESENT => l.attendancePresent,
    ath.AttendanceStatus.LATE => l.attendanceLate,
    ath.AttendanceStatus.ABSENT => l.attendanceAbsent,
    _ => l.attendanceExcused,
  };
}

const attendanceChoices = [
  ath.AttendanceStatus.PRESENT,
  ath.AttendanceStatus.LATE,
  ath.AttendanceStatus.ABSENT,
  ath.AttendanceStatus.EXCUSED,
];

extension CompletionLabel on ath.CompletionStatus {
  String label(AppLocalizations l) => switch (this) {
    ath.CompletionStatus.DONE => l.completionDone,
    ath.CompletionStatus.PARTIAL => l.completionPartial,
    _ => l.completionNotDone,
  };

  ChipTone get tone => switch (this) {
    ath.CompletionStatus.DONE => ChipTone.good,
    ath.CompletionStatus.PARTIAL => ChipTone.warn,
    _ => ChipTone.bad,
  };

  IconData get icon => switch (this) {
    ath.CompletionStatus.DONE => Icons.check_circle_outline,
    ath.CompletionStatus.PARTIAL => Icons.timelapse,
    _ => Icons.cancel_outlined,
  };
}

const completionChoices = [ath.CompletionStatus.DONE, ath.CompletionStatus.PARTIAL, ath.CompletionStatus.NOT_DONE];

String two(int n) => n.toString().padLeft(2, '0');

/// `HH:mm` of the instant [d] in the academy [zone].
String formatTime(DateTime d, TenantZone zone) {
  final t = zone.wall(d);
  return '${two(t.hour)}:${two(t.minute)}';
}

/// `dd/MM`.
String shortDate(DateTime d) => '${two(d.day)}/${two(d.month)}';

/// `dd/MM/yyyy` from a contract date.
String fullDate(ath.Date d) => '${two(d.day)}/${two(d.month)}/${d.year}';
