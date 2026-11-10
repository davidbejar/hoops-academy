import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/export/export_context.dart';
import '../../../core/export/export_runner.dart';
import '../../../core/export/export_table.dart';
import '../../../core/export/ics_writer.dart';
import '../../../core/export/export_menu.dart';
import '../../../core/time/tenant_zone.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../match/presentation/match_labels.dart';
import '../../tenant/application/tenant_providers.dart';
import '../application/team_calendar.dart';
import '../application/training_providers.dart';
import 'training_labels.dart';

/// Table and ICS events of the team calendar (WP97): matches and training
/// sessions merged, with venue and cancel state.

String _team(Map<String, String> names, CalendarEntry e) =>
    names[e.teamId] ?? '';

String _type(AppLocalizations l, CalendarEntry e) => switch (e) {
  MatchEntry() => l.exportKindMatch,
  SessionEntry() => l.exportKindTraining,
};

String _title(AppLocalizations l, CalendarEntry e) => switch (e) {
  MatchEntry(:final match) => l.matchVs(match.opponentName),
  SessionEntry() => l.trainingTitle,
};

String? _venue(CalendarEntry e) => switch (e) {
  MatchEntry(:final match) => match.venue,
  SessionEntry(:final session) => session.location,
};

String _status(AppLocalizations l, CalendarEntry e) => switch (e) {
  MatchEntry(:final match) => statusLabel(l, match.status),
  SessionEntry(:final session) => session.status.label(l),
};

String? _note(CalendarEntry e) => switch (e) {
  MatchEntry(:final match) => match.cancelReason,
  SessionEntry(:final session) => session.cancelReason ?? session.notes,
};

ExportCell _text(String? v) =>
    v == null || v.isEmpty ? const EmptyCell() : TextCell(v);

ExportTable calendarTable(
  AppLocalizations l,
  List<CalendarEntry> entries, {
  required TenantZone zone,
  required Map<String, String> teamNames,
}) => ExportTable(
  sheetName: l.exportSheetCalendar,
  headers: [
    l.matchDate,
    l.exportColTime,
    l.exportColEndTime,
    l.exportColZone,
    l.exportColType,
    l.matchTeam,
    l.exportColEvent,
    l.matchVenue,
    l.exportColStatus,
    l.sessionNotes,
  ],
  rows: [
    for (final e in entries)
      () {
        final start = zone.wall(e.startsAt);
        final end = zone.wall(e.endsAt);
        return <ExportCell>[
          DateCell(start),
          TimeCell(start.hour, start.minute),
          TimeCell(end.hour, end.minute),
          TextCell(zone.label ?? ''),
          TextCell(_type(l, e)),
          _text(_team(teamNames, e)),
          TextCell(_title(l, e)),
          _text(_venue(e)),
          TextCell(_status(l, e)),
          _text(_note(e)),
        ];
      }(),
  ],
);

List<IcsEvent> calendarIcsEvents(
  AppLocalizations l,
  List<CalendarEntry> entries, {
  required Map<String, String> teamNames,
}) => [
  for (final e in entries)
    IcsEvent(
      kind: switch (e) {
        MatchEntry() => 'match',
        SessionEntry() => 'training',
      },
      id: e.id,
      summary: [
        _team(teamNames, e),
        _title(l, e),
      ].where((s) => s.isNotEmpty).join(' · '),
      startsAt: e.startsAt,
      endsAt: e.endsAt,
      location: _venue(e),
      description: _note(e),
      cancelled: e.cancelled,
    ),
];

/// The calendar export of the matches and training lists: reads both sources
/// for the selected season (and [teamId], when one is chosen) and builds the
/// table and the ICS file.
Future<ExportJob> prepareCalendarExport(
  WidgetRef ref,
  AppLocalizations l, {
  String? teamId,
}) async {
  final calendar = await ref
      .read(teamCalendarLoaderProvider)
      .load(teamId: teamId);
  final names = ref.read(teamNamesProvider);
  final zone = ref.read(tenantZoneProvider);
  if (calendar.entries.isEmpty) throw const NothingToExport();
  final teamName = teamId == null ? null : names[teamId];
  final stamp = ref.read(exportClockProvider)().toUtc();
  return ExportJob(
    slug: ref.read(academySlugProvider),
    what: teamName == null ? 'calendar' : 'calendar-$teamName',
    day: exportDay(ref),
    table: calendarTable(l, calendar.entries, zone: zone, teamNames: names),
    ics: () => IcsWriter.encode(
      calendarIcsEvents(l, calendar.entries, teamNames: names),
      zone: IcsZone.named(zone.label),
      stamp: stamp,
    ),
    notice: calendar.matchesMissing
        ? l.exportCalendarNoMatches
        : calendar.sessionsMissing
        ? l.exportCalendarNoSessions
        : null,
  );
}

/// The calendar [ExportMenu] for a list filtered to [teamId].
ExportMenu calendarExportMenu({String? teamId}) => ExportMenu(
  formats: const [ExportFormat.csv, ExportFormat.xlsx, ExportFormat.ics],
  prepare: (ref, l) => prepareCalendarExport(ref, l, teamId: teamId),
);
