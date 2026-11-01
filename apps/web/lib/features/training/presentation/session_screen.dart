import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/training_providers.dart';
import 'training_labels.dart';

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
    final theme = Theme.of(context);
    final s = detail.session;
    final caps = ref.watch(capabilitiesProvider);
    final staff = caps.canManageTraining(s.teamId);
    final end = s.startsAt.add(Duration(minutes: s.durationMinutes));
    final names = ref.watch(teamNamesProvider);
    final planned = s.status == ath.TrainingSessionStatus.PLANNED;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${shortDate(s.startsAt.toLocal())}  ${l.sessionTimeRange(formatTime(end), formatTime(s.startsAt))}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    InfoChip(s.status.label(l), tone: s.status.tone, key: const Key('session-status')),
                  ],
                ),
                if (names[s.teamId] != null) Text(names[s.teamId]!),
                const SizedBox(height: AppTokens.spaceSm),
                _Line(Icons.place_outlined, l.sessionLocation, s.location ?? l.sessionNoLocation),
                _Line(Icons.timer_outlined, l.sessionDuration, l.sessionDurationMinutes(s.durationMinutes)),
                _PlanLine(planId: s.planId),
                if (s.notes != null && s.notes!.isNotEmpty) _Line(Icons.notes, l.sessionNotes, s.notes!),
                if (s.cancelReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.spaceSm),
                    child: Text(
                      l.sessionCancelReasonLine(s.cancelReason!),
                      key: const Key('cancel-reason'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (staff && planned)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
            child: OutlinedButton.icon(
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
                  () => ref.read(sessionDetailProvider(s.id).notifier).cancel(reason),
                  success: l.sessionCancelled,
                );
              },
            ),
          ),
        if (staff && detail.attendance != null && s.status != ath.TrainingSessionStatus.CANCELLED)
          AttendanceSheet(key: ValueKey('attendance-${s.id}'), detail: detail),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppTokens.spaceXs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppTokens.spaceSm),
        Expanded(child: Text('$label: $value')),
      ],
    ),
  );
}

class _PlanLine extends ConsumerWidget {
  const _PlanLine({required this.planId});
  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (planId == null) return _Line(Icons.list_alt, l.sessionPlan, l.sessionNoPlan);
    final plan = ref.watch(planDetailProvider(planId!));
    return _Line(Icons.list_alt, l.sessionPlan, plan.value?.name ?? '…');
  }
}

/// Staff attendance sheet: one row per roster player with PRESENT / LATE
/// (minutes) / ABSENT / EXCUSED, the planned-absence overlay and injuries.
class AttendanceSheet extends ConsumerStatefulWidget {
  const AttendanceSheet({super.key, required this.detail});
  final SessionDetail detail;

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
    final entries = {for (final e in widget.detail.attendance!.entries) e.playerId: e};
    final names = {for (final p in widget.detail.roster) p.player.id: p.player.displayName};
    final ids = [...names.keys, for (final id in entries.keys) if (!names.containsKey(id)) id];
    return [
      for (final id in ids)
        _Row(
          id,
          names[id] ?? id,
          entries[id],
          // The planned-absence overlay pre-fills EXCUSED until the coach decides.
          entries[id]?.status ?? ((entries[id]?.expectedAbsent ?? false) ? ath.AttendanceStatus.EXCUSED : null),
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
      () => ref.read(sessionDetailProvider(widget.detail.session.id).notifier).saveAttendance([
        for (final r in _rows)
          if (r.status != null)
            ath.AttendanceInput((b) => b
              ..playerId = r.playerId
              ..status = r.status
              ..minutesLate = r.status == ath.AttendanceStatus.LATE ? int.parse(r.minutes.text) : null),
      ]),
      success: l.attendanceSaved,
    );
    if (mounted && !ok) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.attendanceTitle, style: theme.textTheme.titleMedium),
              if (_rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceMd),
                  child: Text(l.attendanceEmpty),
                ),
              for (final r in _rows) _rowView(l, theme, r),
              const SizedBox(height: AppTokens.spaceSm),
              if (_rows.isNotEmpty)
                FilledButton(
                  key: const Key('attendance-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(l.attendanceSave),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowView(AppLocalizations l, ThemeData theme, _Row r) {
    final expected = r.entry?.expectedAbsent ?? false;
    final injured = r.entry?.unavailableInjuryId != null;
    return Padding(
      key: Key('att-row-${r.playerId}'),
      padding: const EdgeInsets.only(top: AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTokens.spaceSm,
            runSpacing: AppTokens.spaceXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(r.name, style: theme.textTheme.titleSmall),
              if (expected) InfoChip(l.attendanceExpectedAbsent, tone: ChipTone.warn, icon: Icons.event_busy_outlined),
              if (injured) InfoChip(l.attendanceInjured, tone: ChipTone.bad, icon: Icons.healing),
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          Wrap(
            spacing: AppTokens.spaceSm,
            children: [
              for (final s in attendanceChoices)
                ChoiceChip(
                  key: Key('att-${r.playerId}-${s.name}'),
                  label: Text(s.label(l)),
                  selected: r.status == s,
                  onSelected: (_) => setState(() => r.status = r.status == s ? null : s),
                ),
            ],
          ),
          if (r.status == ath.AttendanceStatus.LATE)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceSm),
              child: SizedBox(
                width: 180,
                child: TextFormField(
                  key: Key('late-minutes-${r.playerId}'),
                  controller: r.minutes,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.attendanceMinutesLate, isDense: true),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 1 || n > 180 ? l.attendanceMinutesInvalid : null;
                  },
                ),
              ),
            ),
          if (r.status == null)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceXs),
              child: Text(l.attendanceNotRecorded, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
