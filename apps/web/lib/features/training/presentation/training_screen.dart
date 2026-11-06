import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../core/ui/timezone_note.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/presentation/eligibility_widgets.dart' show TeamLabel;
import '../application/training_providers.dart';
import '../domain/week.dart';
import 'training_labels.dart';

/// Week calendar of the training module (deferred, behind the Training tab).
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
              onPressed: () => showDialog<bool>(context: context, builder: (_) => const SessionDialog()),
              icon: const Icon(Icons.add),
              label: Text(l.sessionNew),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
          child: Column(
            children: [
              _WeekHeader(monday: monday),
              const TimezoneNote(),
              const _TrainingMenu(),
              if (caps.canManageAnyTraining) const _TeamFilter(),
              Expanded(
                child: AsyncBody<List<ath.TrainingSession>>(
                  value: sessions,
                  onRetry: () => ref.invalidate(weekSessionsProvider),
                  isEmpty: (d) => d.isEmpty,
                  emptyMessage: l.trainingNoSessions,
                  builder: (context, data) => WeekCalendar(monday: monday, sessions: data),
                ),
              ),
            ],
          ),
        ),
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
    final sunday = monday.add(const Duration(days: 6));
    final notifier = ref.read(weekStartProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceSm),
      child: Row(
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
      ),
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
    Widget chip(String key, String label, IconData icon, String path) => ActionChip(
      key: Key(key),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => context.go(path),
    );
    final items = [
      if (caps.canSeeModule) chip('menu-plans', l.trainingMenuPlans, Icons.list_alt, '/training/plans'),
      if (caps.canSeeModule) chip('menu-assignments', l.trainingMenuAssignments, Icons.assignment_outlined, '/training/assignments'),
      if (caps.canManageAnyTraining) chip('menu-schedules', l.trainingMenuSchedules, Icons.event_repeat, '/training/schedules'),
      if (caps.canFileAbsences) chip('menu-absences', l.trainingMenuAbsences, Icons.event_busy_outlined, '/training/absences'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
      child: Row(
        children: [
          for (final item in items)
            Padding(padding: const EdgeInsets.only(right: AppTokens.spaceSm), child: item),
        ],
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
        if (caps.isAdmin || caps.isStaffOf(t.id)) t,
    ];
    if (teams.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 0),
      child: DropdownButtonFormField<String?>(
        key: const Key('team-filter'),
        initialValue: ref.watch(calendarTeamProvider),
        isExpanded: true,
        decoration: InputDecoration(labelText: l.sessionTeam, isDense: true),
        items: [
          DropdownMenuItem(value: null, child: Text(l.trainingAllTeams)),
          for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.displayLabel)),
        ],
        onChanged: (v) => ref.read(calendarTeamProvider.notifier).select(v),
      ),
    );
  }
}

/// Seven day sections, Monday first, with the week's sessions.
class WeekCalendar extends ConsumerWidget {
  const WeekCalendar({super.key, required this.monday, required this.sessions});
  final DateTime monday;
  final List<ath.TrainingSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final zone = ref.watch(tenantZoneProvider);
    final byDay = groupByDay(sessions, (s) => s.startsAt, wall: zone.wall);
    final names = ref.watch(teamNamesProvider);
    final today = zone.today(ref.watch(nowProvider)());
    return ListView(
      key: const Key('week-calendar'),
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 88),
      children: [
        for (final day in weekDays(monday)) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spaceSm, bottom: AppTokens.spaceXs),
            child: Text(
              '${dayOfWeekFor(day.weekday).label(l)} ${shortDate(day)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: sameDay(day, today) ? theme.colorScheme.primary : null,
                fontWeight: sameDay(day, today) ? FontWeight.bold : null,
              ),
            ),
          ),
          if ((byDay[day] ?? const []).isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spaceXs),
              child: Text(l.trainingNoSessionsDay, style: theme.textTheme.bodySmall),
            )
          else
            for (final s in byDay[day]!) SessionTile(session: s, teamName: names[s.teamId]),
        ],
      ],
    );
  }
}

class SessionTile extends ConsumerWidget {
  const SessionTile({super.key, required this.session, this.teamName});
  final ath.TrainingSession session;
  final String? teamName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(tenantZoneProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final end = session.startsAt.add(Duration(minutes: session.durationMinutes));
    final cancelled = session.status == ath.TrainingSessionStatus.CANCELLED;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceSm),
      child: InkWell(
        key: Key('session-${session.id}'),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        onTap: () => context.go('/training/session/${session.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.sessionTimeRange(formatTime(end, zone), formatTime(session.startsAt, zone)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (teamName != null) Text(teamName!, style: theme.textTheme.bodyMedium),
                    if (session.location != null) Text(session.location!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (session.status != ath.TrainingSessionStatus.PLANNED)
                InfoChip(session.status.label(l), tone: session.status.tone),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
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
    return widget.session == null
        ? ref
              .read(weekSessionsProvider.notifier)
              .create(
                teamId: _teamId!,
                startsAt: startsAt,
                durationMinutes: duration,
                location: location,
                planId: _planId,
                notes: notes,
              )
        : ref
              .read(sessionDetailProvider(widget.session!.id).notifier)
              .edit(
                startsAt: startsAt,
                durationMinutes: duration,
                location: location,
                planId: _planId,
                notes: notes,
              );
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
    final plans =
        ref.watch(planLibraryProvider(false)).value ??
        const <ath.TrainingPlanSummary>[];
    return FormDialog(
      title: editing ? l.sessionEdit : l.sessionNew,
      formKey: _form,
      canSubmit: editing || teams.isNotEmpty,
      onSubmit: () => runAction(
        context,
        () => _submit(context, l),
        success: editing ? l.sessionUpdated : l.sessionCreated,
      ),
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
          firstDate: ref.read(tenantZoneProvider).today(DateTime.now()).subtract(const Duration(days: 365)),
        ),
        formGap,
        InkWell(
          key: const Key('session-time'),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: _time);
            if (t != null) setState(() => _time = t);
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: l.sessionStartTime, suffixIcon: const Icon(Icons.schedule)),
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
        DropdownButtonFormField<String?>(
          key: const Key('session-plan'),
          initialValue: _planId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.sessionPlan),
          items: [
            // Choosing "no plan" while editing detaches the plan (`clear`, ADR-0032).
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l.sessionNoPlan),
            ),
            for (final p in plans)
              DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
            if (_planId != null && plans.every((p) => p.id != _planId))
              DropdownMenuItem<String?>(
                value: _planId,
                child: Text(
                  ref.watch(planDetailProvider(_planId!)).value?.name ?? '…',
                ),
              ),
          ],
          onChanged: (v) => setState(() => _planId = v),
        ),
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
}
