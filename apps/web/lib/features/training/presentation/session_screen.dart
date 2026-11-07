import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../application/training_providers.dart';
import 'plan_search.dart';
import 'training_labels.dart';
import 'training_screen.dart' show SessionDialog;

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(sessionDetailProvider(sessionId));
    return SubPage(
      title: l.sessionDetailTitle,
      parentPath: '/training',
      child: AsyncBody<SessionDetail>(
        value: detail,
        onRetry: () => ref.invalidate(sessionDetailProvider(sessionId)),
        builder: (context, d) => _Body(detail: d),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail});
  final SessionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final s = detail.session;
    final caps = ref.watch(capabilitiesProvider);
    final staff = caps.canManageTraining(s.teamId);
    // The whole sheet is readable by former staff and by the admin of an ended season (ADR-0042), not editable.
    final canRead = caps.canReadTraining(s.teamId);
    final zone = ref.watch(tenantZoneProvider);
    final end = s.startsAt.add(Duration(minutes: s.durationMinutes));
    final names = ref.watch(teamNamesProvider);
    final planned = s.status == ath.TrainingSessionStatus.PLANNED;
    final cancelled = s.status == ath.TrainingSessionStatus.CANCELLED;
    final actions = [
      if (staff && planned)
        OutlinedButton.icon(
          key: const Key('session-edit'),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l.sessionEdit),
          onPressed: () => showDialog<bool>(
            context: context,
            builder: (_) => SessionDialog(session: s),
          ),
        ),
      if (staff && !cancelled)
        OutlinedButton.icon(
          key: const Key('session-add-exercises'),
          icon: const Icon(Icons.playlist_add),
          label: Text(l.sessionAddExercises),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => ExerciseSearchDialog(sessionId: s.id),
          ),
        ),
      if (staff && planned)
        OutlinedButton.icon(
          key: const Key('session-cancel'),
          icon: const Icon(Icons.event_busy),
          label: Text(l.sessionCancel),
          onPressed: () async {
            final reason = await noteDialog(
              context,
              title: l.sessionCancel,
              confirmLabel: l.sessionCancel,
              required: true,
              label: l.sessionCancelReason,
            );
            if (reason == null || !context.mounted) return;
            await runAction(
              context,
              () =>
                  ref.read(sessionDetailProvider(s.id).notifier).cancel(reason),
              success: l.sessionCancelled,
            );
          },
        ),
    ];
    return PageBody(
      children: [
        SectionCard(
          title:
              '${shortDate(zone.wall(s.startsAt))}  ${l.sessionTimeRange(formatTime(end, zone), formatTime(s.startsAt, zone))}',
          subtitle: names[s.teamId],
          actions: [
            StatusChip(
              s.status.label(l),
              tone: s.status.tone,
              key: const Key('session-status'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: HoopsSpace.sm,
            children: [
              _Line(
                Icons.place_outlined,
                l.sessionLocation,
                s.location ?? l.sessionNoLocation,
              ),
              _Line(
                Icons.timer_outlined,
                l.sessionDuration,
                l.sessionDurationMinutes(s.durationMinutes),
              ),
              _PlanLine(session: s),
              if (s.notes != null && s.notes!.isNotEmpty)
                _Line(Icons.notes, l.sessionNotes, s.notes!),
              if (s.cancelReason != null)
                Text(
                  l.sessionCancelReasonLine(s.cancelReason!),
                  key: const Key('cancel-reason'),
                  style: text.bodyMedium!.copyWith(color: c.danger.foreground),
                ),
            ],
          ),
        ),
        if (actions.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: HoopsSpace.sm,
              runSpacing: HoopsSpace.sm,
              children: actions,
            ),
          ),
        if (canRead && detail.attendance != null && !cancelled)
          AttendanceSheet(
            key: ValueKey('attendance-${s.id}'),
            detail: detail,
            readOnly: !staff,
          ),
      ],
    );
  }
}

/// An icon, a label and its value: one fact of the session.
class _Line extends StatelessWidget {
  const _Line(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.sm,
      children: [
        Icon(icon, color: c.brand),
        Expanded(child: Text('$label: $value')),
      ],
    );
  }
}

/// The session's plan and its exercises; marks the session's own plan
/// (quick-added exercises, ADR-0041).
class _PlanLine extends ConsumerWidget {
  const _PlanLine({required this.session});
  final ath.TrainingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final planId = session.planId;
    if (planId == null) {
      return _Line(Icons.list_alt, l.sessionPlan, l.sessionNoPlan);
    }
    final plan = ref.watch(planDetailProvider(planId)).value;
    final indent = IconTheme.of(context).size! + HoopsSpace.sm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.xs,
      children: [
        _Line(Icons.list_alt, l.sessionPlan, plan?.name ?? '…'),
        if (plan?.sessionId == session.id)
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: StatusChip(
              l.sessionOwnPlan,
              key: const Key('session-own-plan'),
              tone: HoopsTone.accent,
            ),
          ),
        for (final item in plan?.items ?? const <ath.PlanItem>[])
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.position + 1}. ',
                  style: text.bodyMedium!.copyWith(color: c.inkMuted),
                ),
                Expanded(child: Text(item.title)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Staff attendance sheet: one row per roster player with PRESENT / LATE
/// (minutes) / ABSENT / EXCUSED, the planned-absence overlay and injuries.
class AttendanceSheet extends ConsumerStatefulWidget {
  const AttendanceSheet({
    super.key,
    required this.detail,
    this.readOnly = false,
  });
  final SessionDetail detail;

  /// The sheet of a past season: statuses are shown, nothing can be changed.
  final bool readOnly;

  @override
  ConsumerState<AttendanceSheet> createState() => _AttendanceSheetState();
}

class _Row {
  _Row(this.playerId, this.name, this.entry, this.status, int? minutes)
    : minutes = TextEditingController(text: minutes?.toString() ?? '10');
  final String playerId;
  final String name;
  final ath.AttendanceEntry? entry;
  ath.AttendanceStatus? status;
  final TextEditingController minutes;
}

class _AttendanceSheetState extends ConsumerState<AttendanceSheet> {
  late final List<_Row> _rows = _build();
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  List<_Row> _build() {
    final entries = {
      for (final e in widget.detail.attendance!.entries) e.playerId: e,
    };
    final names = {
      for (final p in widget.detail.roster) p.player.id: p.player.displayName,
    };
    final ids = [
      ...names.keys,
      for (final id in entries.keys)
        if (!names.containsKey(id)) id,
    ];
    return [
      for (final id in ids)
        _Row(
          id,
          names[id] ?? id,
          entries[id],
          // The planned-absence overlay pre-fills EXCUSED until the coach decides.
          entries[id]?.status ??
              ((entries[id]?.expectedAbsent ?? false)
                  ? ath.AttendanceStatus.EXCUSED
                  : null),
          entries[id]?.minutesLate,
        ),
    ];
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.minutes.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(sessionDetailProvider(widget.detail.session.id).notifier)
          .saveAttendance([
            for (final r in _rows)
              if (r.status != null)
                ath.AttendanceInput(
                  (b) => b
                    ..playerId = r.playerId
                    ..status = r.status
                    ..minutesLate = r.status == ath.AttendanceStatus.LATE
                        ? int.parse(r.minutes.text)
                        : null,
                ),
          ]),
      success: l.attendanceSaved,
    );
    if (mounted && !ok) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.attendanceTitle,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_rows.isEmpty) Text(l.attendanceEmpty),
            for (final (i, r) in _rows.indexed) ...[
              if (i > 0) const Divider(height: HoopsSpace.lg),
              _rowView(l, r),
            ],
            if (_rows.isNotEmpty && !widget.readOnly) ...[
              const SizedBox(height: HoopsSpace.md),
              FilledButton(
                key: const Key('attendance-save'),
                onPressed: _busy ? null : _save,
                child: Text(l.attendanceSave),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rowView(AppLocalizations l, _Row r) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final expected = r.entry?.expectedAbsent ?? false;
    final injured = r.entry?.unavailableInjuryId != null;
    return Column(
      key: Key('att-row-${r.playerId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.sm,
      children: [
        Wrap(
          spacing: HoopsSpace.sm,
          runSpacing: HoopsSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(r.name, style: text.titleSmall),
            if (expected)
              StatusChip(
                l.attendanceExpectedAbsent,
                tone: HoopsTone.warning,
                icon: Icons.event_busy_outlined,
              ),
            if (injured)
              StatusChip(
                l.attendanceInjured,
                tone: HoopsTone.danger,
                icon: Icons.healing,
              ),
          ],
        ),
        Wrap(
          spacing: HoopsSpace.sm,
          runSpacing: HoopsSpace.sm,
          children: [
            for (final s in attendanceChoices)
              ChoiceChip(
                key: Key('att-${r.playerId}-${s.name}'),
                label: Text(s.label(l)),
                selected: r.status == s,
                onSelected: widget.readOnly
                    ? null
                    : (_) =>
                          setState(() => r.status = r.status == s ? null : s),
              ),
          ],
        ),
        if (r.status == ath.AttendanceStatus.LATE && !widget.readOnly)
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: HoopsSize.minTapTarget * 4,
            ),
            child: TextFormField(
              key: Key('late-minutes-${r.playerId}'),
              controller: r.minutes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.attendanceMinutesLate,
                isDense: true,
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return n == null || n < 1 || n > 180
                    ? l.attendanceMinutesInvalid
                    : null;
              },
            ),
          ),
        if (r.status == null)
          Text(
            l.attendanceNotRecorded,
            style: text.bodySmall!.copyWith(color: c.inkMuted),
          ),
      ],
    );
  }
}
