import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/presentation/eligibility_widgets.dart' show TeamLabel;
import '../application/training_providers.dart';
import 'training_labels.dart';

/// Weekly schedule editor (ADMIN / team staff).
class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final schedules = ref.watch(schedulesProvider);
    final names = ref.watch(teamNamesProvider);
    return SubPage(
      title: l.scheduleTitle,
      parentPath: '/training',
      floatingActionButton: caps.canManageAnyTraining
          ? FloatingActionButton.extended(
              key: const Key('schedule-new'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const ScheduleDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.scheduleNew),
            )
          : null,
      child: Guarded(
        allowed: caps.canSeeModule,
        child: AsyncBody<List<ath.TrainingSchedule>>(
          value: schedules,
          onRetry: () => ref.invalidate(schedulesProvider),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.scheduleEmpty,
          builder: (context, data) => ListView.separated(
            padding: const EdgeInsets.only(
              top: HoopsSpace.md,
              bottom: HoopsSize.fabClearance,
            ),
            itemCount: data.length,
            separatorBuilder: (_, _) => const SizedBox(height: HoopsSpace.gap),
            itemBuilder: (context, i) {
              final s = data[i];
              final canManage = caps.canManageTraining(s.teamId);
              return ContentFrame(
                child: ListRow(
                  key: Key('schedule-${s.id}'),
                  leading: const IconTile(Icons.event_repeat),
                  title: l.scheduleLine(
                    s.dayOfWeek.label(l),
                    s.durationMinutes,
                    s.startTime.substring(0, 5),
                  ),
                  subtitle: [
                    if (names[s.teamId] != null) names[s.teamId]!,
                    if (s.location != null) s.location!,
                    s.validUntil == null
                        ? l.scheduleValidity(fullDate(s.validFrom))
                        : l.scheduleValidityRange(
                            fullDate(s.validFrom),
                            fullDate(s.validUntil!),
                          ),
                  ].join(' · '),
                  onTap: canManage
                      ? () => showDialog<bool>(
                          context: context,
                          builder: (_) => ScheduleDialog(schedule: s),
                        )
                      : null,
                  trailing: canManage
                      ? IconButton(
                          key: Key('schedule-delete-${s.id}'),
                          tooltip: l.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await confirmDialog(
                              context,
                              message: l.scheduleDeleteConfirm,
                              confirmLabel: l.delete,
                            ))
                              return;
                            if (!context.mounted) return;
                            await runAction(
                              context,
                              () => ref
                                  .read(schedulesProvider.notifier)
                                  .delete(s.id),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ScheduleDialog extends ConsumerStatefulWidget {
  const ScheduleDialog({super.key, this.schedule});
  final ath.TrainingSchedule? schedule;

  @override
  ConsumerState<ScheduleDialog> createState() => _ScheduleDialogState();
}

final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

class _ScheduleDialogState extends ConsumerState<ScheduleDialog> {
  final _form = GlobalKey<FormState>();
  late String? _teamId = widget.schedule?.teamId;
  late ath.DayOfWeek _day = widget.schedule?.dayOfWeek ?? ath.DayOfWeek.MONDAY;
  late final _time = TextEditingController(
    text: widget.schedule?.startTime.substring(0, 5) ?? '18:00',
  );
  late final _duration = TextEditingController(
    text: '${widget.schedule?.durationMinutes ?? 90}',
  );
  late final _location = TextEditingController(text: widget.schedule?.location);
  late DateTime _from =
      widget.schedule?.validFrom.toDateTime() ?? DateTime.now();
  late DateTime? _until = widget.schedule?.validUntil?.toDateTime();
  bool _datesBad = false;

  @override
  void dispose() {
    _time.dispose();
    _duration.dispose();
    _location.dispose();
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
    final editing = widget.schedule != null;
    return FormDialog(
      title: editing ? l.scheduleEdit : l.scheduleNew,
      formKey: _form,
      validateExtra: () {
        final bad = _until != null && _until!.isBefore(_from);
        setState(() => _datesBad = bad);
        return !bad;
      },
      onSubmit: () => runAction(
        context,
        () => ref
            .read(schedulesProvider.notifier)
            .save(
              scheduleId: widget.schedule?.id,
              teamId: _teamId!,
              day: _day,
              startTime: _time.text,
              durationMinutes: int.parse(_duration.text),
              location: _location.text.trim().isEmpty
                  ? null
                  : _location.text.trim(),
              validFrom: _from,
              validUntil: _until,
            ),
        success: l.saved,
      ),
      children: [
        if (!editing) ...[
          DropdownButtonFormField<String>(
            key: const Key('schedule-team'),
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
        DropdownButtonFormField<ath.DayOfWeek>(
          key: const Key('schedule-day'),
          initialValue: _day,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.scheduleDay),
          items: [
            for (final d in weekdays)
              DropdownMenuItem(value: d, child: Text(d.label(l))),
          ],
          onChanged: (v) => setState(() => _day = v ?? _day),
        ),
        formGap,
        TextFormField(
          key: const Key('schedule-time'),
          controller: _time,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(labelText: l.scheduleTime),
          validator: (v) => _timePattern.hasMatch((v ?? '').trim())
              ? null
              : l.scheduleTimeInvalid,
        ),
        formGap,
        TextFormField(
          key: const Key('schedule-duration'),
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
          key: const Key('schedule-location'),
          controller: _location,
          decoration: InputDecoration(labelText: l.sessionLocation),
        ),
        formGap,
        DateField(
          key: const Key('schedule-from'),
          label: l.scheduleValidFrom,
          value: _from,
          onChanged: (d) => setState(() => _from = d),
        ),
        formGap,
        DateField(
          key: const Key('schedule-until'),
          label: l.scheduleValidUntil,
          value: _until,
          errorText: _datesBad ? l.scheduleDatesInvalid : null,
          onChanged: (d) => setState(() => _until = d),
          onClear: () => setState(() => _until = null),
        ),
      ],
    );
  }
}
