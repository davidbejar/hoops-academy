import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/timezone_note.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/presentation/eligibility_widgets.dart' show TeamLabel;
import '../../roster/presentation/season_bar.dart';
import '../application/training_providers.dart';
import '../domain/exercise_pick.dart';
import '../domain/week.dart';
import 'calendar_exports.dart';
import 'plan_search.dart';
import 'training_labels.dart';

/// Week calendar of the training module (deferred, behind the Training tab):
/// the week switcher, the academy's time zone, shortcuts to the other
/// training screens, the team filter and one section per day
/// (`assets/landing/training_week.png`).
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final monday = ref.watch(weekStartProvider);
    final sessions = ref.watch(weekSessionsProvider);
    return Scaffold(
      floatingActionButton: caps.canManageAnyTraining
          ? FloatingActionButton.extended(
              key: const Key('session-new'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const SessionDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.sessionNew),
            )
          : null,
      body: Column(
        children: [
          ContentFrame(
            child: Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WeekHeader(monday: monday),
                  Row(
                    children: [
                      const Expanded(child: TimezoneNote()),
                      calendarExportMenu(
                        teamId: ref.watch(calendarTeamProvider),
                      ),
                    ],
                  ),
                  SeasonBar(
                    onChanged: (season) {
                      // The calendar follows the season: its last week, or this week again.
                      ref.read(calendarTeamProvider.notifier).select(null);
                      final week = ref.read(weekStartProvider.notifier);
                      season == null || season.current
                          ? week.today()
                          : week.set(season.endsOn.toDateTime());
                    },
                  ),
                  const _TrainingMenu(),
                  if (caps.canManageAnyTraining || caps.viewingPastSeason)
                    const _TeamFilter(),
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<ath.TrainingSession>>(
              value: sessions,
              onRetry: () => ref.invalidate(weekSessionsProvider),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: l.trainingNoSessions,
              builder: (context, data) =>
                  WeekCalendar(monday: monday, sessions: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({required this.monday});
  final DateTime monday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final sunday = monday.add(const Duration(days: 6));
    final notifier = ref.read(weekStartProvider.notifier);
    return Row(
      children: [
        IconButton(
          key: const Key('week-prev'),
          tooltip: l.trainingPrevWeek,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.shift(-1),
        ),
        Expanded(
          child: TextButton(
            key: const Key('week-today'),
            onPressed: notifier.today,
            style: TextButton.styleFrom(
              foregroundColor: c.accentText,
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
            child: Text(
              l.trainingWeekOf('${shortDate(monday)} – ${shortDate(sunday)}'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          key: const Key('week-next'),
          tooltip: l.trainingNextWeek,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => notifier.shift(1),
        ),
      ],
    );
  }
}

/// Role-aware shortcuts to the other training screens.
class _TrainingMenu extends ConsumerWidget {
  const _TrainingMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final c = HoopsTokens.colorsOf(context);
    Widget chip(String key, String label, IconData icon, String path) =>
        ActionChip(
          key: Key(key),
          avatar: Icon(icon, color: c.brand),
          label: Text(label),
          onPressed: () => context.go(path),
        );
    final items = [
      if (caps.canSeeModule)
        chip(
          'menu-plans',
          l.trainingMenuPlans,
          Icons.list_alt,
          '/training/plans',
        ),
      if (caps.canSeeModule)
        chip(
          'menu-assignments',
          l.trainingMenuAssignments,
          Icons.assignment_outlined,
          '/training/assignments',
        ),
      if (caps.canManageAnyTraining)
        chip(
          'menu-schedules',
          l.trainingMenuSchedules,
          Icons.event_repeat,
          '/training/schedules',
        ),
      if (caps.canFileAbsences)
        chip(
          'menu-absences',
          l.trainingMenuAbsences,
          Icons.event_busy_outlined,
          '/training/absences',
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: HoopsSpace.gap),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(spacing: HoopsSpace.sm, children: items),
      ),
    );
  }
}

class _TeamFilter extends ConsumerWidget {
  const _TeamFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final teams = [
      for (final t in ref.watch(teamsProvider).value ?? const <api.Team>[])
        if (caps.isAdmin ||
            caps.isStaffOf(t.id) ||
            caps.historicStaffTeamIds.contains(t.id))
          t,
    ];
    if (teams.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: HoopsSpace.md),
      child: DropdownButtonFormField<String?>(
        key: const Key('team-filter'),
        initialValue: ref.watch(calendarTeamProvider),
        isExpanded: true,
        decoration: InputDecoration(labelText: l.sessionTeam, isDense: true),
        items: [
          DropdownMenuItem(value: null, child: Text(l.trainingAllTeams)),
          for (final t in teams)
            DropdownMenuItem(value: t.id, child: Text(t.displayLabel)),
        ],
        onChanged: (v) => ref.read(calendarTeamProvider.notifier).select(v),
      ),
    );
  }
}

/// Seven day sections, Monday first, with the week's sessions; today's
/// heading is orange and marked "today".
class WeekCalendar extends ConsumerWidget {
  const WeekCalendar({super.key, required this.monday, required this.sessions});
  final DateTime monday;
  final List<ath.TrainingSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = HoopsTokens.colorsOf(context);
    final zone = ref.watch(tenantZoneProvider);
    final byDay = groupByDay(sessions, (s) => s.startsAt, wall: zone.wall);
    final names = ref.watch(teamNamesProvider);
    final today = zone.today(ref.watch(nowProvider)());
    Widget framed(Widget child) => ContentFrame(child: child);
    return ListView(
      key: const Key('week-calendar'),
      padding: const EdgeInsets.only(
        top: HoopsSpace.sm,
        bottom: HoopsSize.fabClearance,
      ),
      children: [
        for (final day in weekDays(monday)) ...[
          framed(
            Padding(
              padding: const EdgeInsets.only(
                top: HoopsSpace.md,
                bottom: HoopsSpace.sm,
              ),
              child: Row(
                spacing: HoopsSpace.sm,
                children: [
                  Text(
                    '${dayOfWeekFor(day.weekday).label(l)} ${shortDate(day)}',
                    style: text.titleSmall!.copyWith(
                      color: sameDay(day, today) ? c.accentText : c.ink,
                      fontWeight: sameDay(day, today) ? FontWeight.w800 : null,
                    ),
                  ),
                  if (sameDay(day, today))
                    StatusChip(
                      l.trainingToday,
                      key: const Key('week-today-marker'),
                      tone: HoopsTone.accent,
                    ),
                ],
              ),
            ),
          ),
          if ((byDay[day] ?? const []).isEmpty)
            framed(
              Text(
                l.trainingNoSessionsDay,
                style: text.bodySmall!.copyWith(color: c.inkMuted),
              ),
            )
          else
            for (final s in byDay[day]!)
              framed(
                Padding(
                  padding: const EdgeInsets.only(bottom: HoopsSpace.sm),
                  child: SessionTile(session: s, teamName: names[s.teamId]),
                ),
              ),
        ],
      ],
    );
  }
}

/// One session of the week: time range, team, place and its state.
class SessionTile extends ConsumerWidget {
  const SessionTile({super.key, required this.session, this.teamName});
  final ath.TrainingSession session;
  final String? teamName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(tenantZoneProvider);
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = HoopsTokens.colorsOf(context);
    final end = session.startsAt.add(
      Duration(minutes: session.durationMinutes),
    );
    final place = session.location;
    return ListRow(
      key: Key('session-${session.id}'),
      title: l.sessionTimeRange(
        formatTime(end, zone),
        formatTime(session.startsAt, zone),
      ),
      subtitle: teamName,
      details: place == null
          ? null
          : Row(
              spacing: HoopsSpace.xs,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: HoopsSpace.md,
                  color: c.inkMuted,
                ),
                Flexible(
                  child: Text(
                    place,
                    style: text.bodySmall!.copyWith(color: c.inkMuted),
                  ),
                ),
              ],
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: HoopsSpace.xs,
        children: [
          if (session.status != ath.TrainingSessionStatus.PLANNED)
            StatusChip(session.status.label(l), tone: session.status.tone),
          Icon(Icons.chevron_right, color: c.inkMuted),
        ],
      ),
      onTap: () => context.go('/training/session/${session.id}'),
    );
  }
}

/// Ad-hoc session creation, or editing of [session] (the team cannot change).
class SessionDialog extends ConsumerStatefulWidget {
  const SessionDialog({super.key, this.session});
  final ath.TrainingSession? session;

  @override
  ConsumerState<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends ConsumerState<SessionDialog> {
  final _form = GlobalKey<FormState>();
  late final _duration = TextEditingController(
    text: '${widget.session?.durationMinutes ?? 90}',
  );
  late final _location = TextEditingController(
    text: widget.session?.location ?? '',
  );
  late final _notes = TextEditingController(text: widget.session?.notes ?? '');
  late String? _teamId = widget.session?.teamId;
  String? _planId;
  late DateTime _date =
      _initialWall()?.copyWith(hour: 0, minute: 0) ??
      ref.read(tenantZoneProvider).today(DateTime.now());
  late TimeOfDay _time = _initialTime();

  /// A new session's exercises, quick-added once it exists (decision 72).
  final _picks = <ExercisePick>[];

  /// Set once the new session exists: a failed quick-add must not create it
  /// again, so the dialog closes and says why.
  ath.TrainingSession? _created;

  @override
  void initState() {
    super.initState();
    _planId = widget.session?.planId;
  }

  DateTime? _initialWall() {
    final s = widget.session;
    return s == null ? null : ref.read(tenantZoneProvider).wall(s.startsAt);
  }

  TimeOfDay _initialTime() {
    final w = _initialWall();
    return w == null
        ? const TimeOfDay(hour: 18, minute: 0)
        : TimeOfDay(hour: w.hour, minute: w.minute);
  }

  Future<void> _submit(BuildContext context, AppLocalizations l) {
    final startsAt = ref
        .read(tenantZoneProvider)
        .instant(
          DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time.hour,
            _time.minute,
          ),
        );
    final duration = int.parse(_duration.text);
    final location = _location.text.trim().isEmpty
        ? null
        : _location.text.trim();
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final editing = widget.session;
    if (editing != null) {
      return ref
          .read(sessionDetailProvider(editing.id).notifier)
          .edit(
            startsAt: startsAt,
            durationMinutes: duration,
            location: location,
            planId: _planId,
            notes: notes,
          );
    }
    return _create(
      startsAt: startsAt,
      duration: duration,
      location: location,
      notes: notes,
    );
  }

  Future<void> _create({
    required DateTime startsAt,
    required int duration,
    String? location,
    String? notes,
  }) async {
    final week = ref.read(weekSessionsProvider.notifier);
    final created = _created ??= await week.create(
      teamId: _teamId!,
      startsAt: startsAt,
      durationMinutes: duration,
      location: location,
      planId: _planId,
      notes: notes,
    );
    if (_picks.isNotEmpty) {
      await week.addExercises(created.id, [for (final p in _picks) p.source]);
    }
  }

  String _errorText(Object error, AppLocalizations l) {
    final reason = exerciseErrorText(error, l);
    return _created == null ? reason : l.sessionCreatedExercisesFailed(reason);
  }

  Future<void> _pickExercises() async {
    final picks = await showDialog<List<ExercisePick>>(
      context: context,
      builder: (_) => const ExerciseSearchDialog(),
    );
    if (picks != null) setState(() => _picks.addAll(picks));
  }

  /// Leaving the session's own plan deletes it with its quick-added exercises.
  bool _dropsOwnPlan() {
    final s = widget.session;
    if (s?.planId == null || s!.planId == _planId) return false;
    return ref.watch(planDetailProvider(s.planId!)).value?.sessionId == s.id;
  }

  @override
  void dispose() {
    _duration.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final teams = [
      for (final t in ref.watch(teamsProvider).value ?? const <api.Team>[])
        if (caps.canManageTraining(t.id)) t,
    ];
    final editing = widget.session != null;
    return FormDialog(
      title: editing ? l.sessionEdit : l.sessionNew,
      formKey: _form,
      canSubmit: editing || teams.isNotEmpty,
      onSubmit: () async {
        final ok = await runAction(
          context,
          () => _submit(context, l),
          success: editing ? l.sessionUpdated : l.sessionCreated,
          errorText: _errorText,
        );
        return ok || _created != null;
      },
      children: [
        if (!editing) ...[
          DropdownButtonFormField<String>(
            key: const Key('session-team'),
            initialValue: _teamId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.sessionTeam),
            items: [
              for (final t in teams)
                DropdownMenuItem(value: t.id, child: Text(t.displayLabel)),
            ],
            validator: (v) => v == null ? l.fieldRequired : null,
            onChanged: (v) => setState(() => _teamId = v),
          ),
          formGap,
        ],
        DateField(
          key: const Key('session-date'),
          label: l.sessionDate,
          value: _date,
          onChanged: (d) => setState(() => _date = d),
          firstDate: ref
              .read(tenantZoneProvider)
              .today(DateTime.now())
              .subtract(const Duration(days: 365)),
        ),
        formGap,
        InkWell(
          key: const Key('session-time'),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: _time,
            );
            if (t != null) setState(() => _time = t);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.sessionStartTime,
              suffixIcon: const Icon(Icons.schedule),
            ),
            child: Text('${two(_time.hour)}:${two(_time.minute)}'),
          ),
        ),
        formGap,
        TextFormField(
          key: const Key('session-duration'),
          controller: _duration,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.sessionDuration),
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            return n == null || n < 15 || n > 300 ? l.fieldInvalidNumber : null;
          },
        ),
        formGap,
        TextFormField(
          key: const Key('session-location'),
          controller: _location,
          decoration: InputDecoration(labelText: l.sessionLocation),
        ),
        formGap,
        // Any academy plan or template, picked directly (decision 53); "no
        // plan" while editing detaches the plan (`clear`, ADR-0032).
        InkWell(
          key: const Key('session-plan'),
          onTap: () async {
            final choice = await showDialog<PlanChoice>(
              context: context,
              builder: (_) => PlanPickerDialog(selected: _planId),
            );
            if (choice != null) setState(() => _planId = choice.planId);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.sessionPlan,
              suffixIcon: const Icon(Icons.search),
              helperText: _dropsOwnPlan() ? l.sessionOwnPlanDropped : null,
            ),
            child: Text(
              _planId == null
                  ? l.sessionNoPlan
                  : ref.watch(planDetailProvider(_planId!)).value?.name ?? '…',
            ),
          ),
        ),
        if (!editing) ...[formGap, ..._exercises(l)],
        formGap,
        TextFormField(
          key: const Key('session-notes'),
          controller: _notes,
          maxLines: 2,
          decoration: InputDecoration(labelText: l.sessionNotes),
        ),
      ],
    );
  }

  /// The exercises picked for a new session, in order, and the picker.
  List<Widget> _exercises(AppLocalizations l) => [
    for (final (i, pick) in _picks.indexed)
      Row(
        key: Key('session-pick-$i'),
        children: [
          Text('${i + 1}. '),
          Expanded(child: Text(pick.title)),
          IconButton(
            key: Key('session-pick-remove-$i'),
            tooltip: l.delete,
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _picks.removeAt(i)),
          ),
        ],
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: const Key('session-exercises'),
        icon: const Icon(Icons.playlist_add),
        label: Text(l.sessionAddExercises),
        onPressed: _pickExercises,
      ),
    ),
  ];
}
