import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/training_providers.dart';
import 'player_picker.dart';
import 'training_labels.dart';

/// Planned absences: staff (any player), PARENT (linked), PLAYER (self).
class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final absences = ref.watch(absencesProvider);
    return SubPage(
      title: l.absenceTitle,
      parentPath: '/training',
      floatingActionButton: caps.canFileAbsences
          ? FloatingActionButton.extended(
              key: const Key('absence-new'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const AbsenceDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.absenceNew),
            )
          : null,
      child: AsyncBody<List<ath.PlannedAbsence>>(
        value: absences,
        onRetry: () => ref.invalidate(absencesProvider),
        isEmpty: (d) => d.isEmpty,
        emptyMessage: l.absenceEmpty,
        builder: (context, data) => ListView.separated(
          padding: const EdgeInsets.only(
            top: HoopsSpace.md,
            bottom: fabClearance,
          ),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: HoopsSpace.gap),
          itemBuilder: (context, i) {
            final a = data[i];
            final name =
                ref.watch(playerNameProvider(a.playerId)) ?? a.playerId;
            return ContentFrame(
              child: ListRow(
                key: Key('absence-${a.id}'),
                leading: InitialsAvatar(name: name, tone: HoopsTone.warning),
                title: name,
                subtitle: [
                  l.absenceRange(fullDate(a.fromDate), fullDate(a.toDate)),
                  if (a.reason != null) a.reason!,
                ].join(' · '),
                trailing: caps.canFileAbsenceFor(a.playerId)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('absence-edit-${a.id}'),
                            tooltip: l.edit,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => showDialog<bool>(
                              context: context,
                              builder: (_) => AbsenceDialog(absence: a),
                            ),
                          ),
                          IconButton(
                            key: Key('absence-delete-${a.id}'),
                            tooltip: l.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (!await confirmDialog(
                                context,
                                message: l.absenceDeleteConfirm,
                                confirmLabel: l.delete,
                              ))
                                return;
                              if (!context.mounted) return;
                              await runAction(
                                context,
                                () => ref
                                    .read(absencesProvider.notifier)
                                    .delete(a.id),
                              );
                            },
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Files a planned absence, or corrects [absence].
class AbsenceDialog extends ConsumerStatefulWidget {
  const AbsenceDialog({super.key, this.absence});
  final ath.PlannedAbsence? absence;

  @override
  ConsumerState<AbsenceDialog> createState() => _AbsenceDialogState();
}

class _AbsenceDialogState extends ConsumerState<AbsenceDialog> {
  final _form = GlobalKey<FormState>();
  late final _reason = TextEditingController(
    text: widget.absence?.reason ?? '',
  );
  String? _playerId;
  late DateTime _from = widget.absence?.fromDate.toDateTime() ?? DateTime.now();
  late DateTime _to = widget.absence?.toDate.toDateTime() ?? DateTime.now();
  bool _bad = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ids = ref.watch(selectablePlayerIdsProvider);
    final editing = widget.absence;
    return FormDialog(
      title: editing == null ? l.absenceNew : l.absenceEdit,
      formKey: _form,
      validateExtra: () {
        final bad = _to.isBefore(_from);
        setState(() => _bad = bad);
        return !bad;
      },
      onSubmit: () => runAction(
        context,
        () => editing == null
            ? ref
                  .read(absencesProvider.notifier)
                  .create(
                    playerId: _playerId ?? ids.first,
                    from: _from,
                    to: _to,
                    reason: _reason.text.trim().isEmpty
                        ? null
                        : _reason.text.trim(),
                  )
            : ref
                  .read(absencesProvider.notifier)
                  .correct(
                    editing.id,
                    from: _from,
                    to: _to,
                    reason: _reason.text.trim().isEmpty
                        ? null
                        : _reason.text.trim(),
                  ),
        success: l.absenceSaved,
      ),
      children: [
        if (editing == null) ...[
          PlayerPicker(
            label: l.absencePlayer,
            value: _playerId,
            onChanged: (v) => setState(() => _playerId = v),
          ),
          formGap,
        ],
        DateField(
          key: const Key('absence-from'),
          label: l.absenceFrom,
          value: _from,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          onChanged: (d) => setState(() => _from = d),
        ),
        formGap,
        DateField(
          key: const Key('absence-to'),
          label: l.absenceTo,
          value: _to,
          errorText: _bad ? l.absenceDatesInvalid : null,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          onChanged: (d) => setState(() => _to = d),
        ),
        formGap,
        TextFormField(
          key: const Key('absence-reason'),
          controller: _reason,
          decoration: InputDecoration(labelText: l.absenceReason),
        ),
      ],
    );
  }
}
