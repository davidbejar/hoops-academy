import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
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
              onPressed: () => showDialog<bool>(context: context, builder: (_) => const AbsenceDialog()),
              icon: const Icon(Icons.add),
              label: Text(l.absenceNew),
            )
          : null,
      child: AsyncBody<List<ath.PlannedAbsence>>(
        value: absences,
        onRetry: () => ref.invalidate(absencesProvider),
        isEmpty: (d) => d.isEmpty,
        emptyMessage: l.absenceEmpty,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 88),
          children: [
            for (final a in data)
              Card(
                child: ListTile(
                  key: Key('absence-${a.id}'),
                  title: Text(ref.watch(playerNameProvider(a.playerId)) ?? a.playerId),
                  subtitle: Text(
                    [l.absenceRange(fullDate(a.fromDate), fullDate(a.toDate)), if (a.reason != null) a.reason!].join(' · '),
                  ),
                  trailing: caps.canFileAbsenceFor(a.playerId)
                      ? IconButton(
                          key: Key('absence-delete-${a.id}'),
                          tooltip: l.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await confirmDialog(context, message: l.absenceDeleteConfirm, confirmLabel: l.delete)) return;
                            if (!context.mounted) return;
                            await runAction(context, () => ref.read(absencesProvider.notifier).delete(a.id));
                          },
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AbsenceDialog extends ConsumerStatefulWidget {
  const AbsenceDialog({super.key});

  @override
  ConsumerState<AbsenceDialog> createState() => _AbsenceDialogState();
}

class _AbsenceDialogState extends ConsumerState<AbsenceDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _playerId;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
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
    return FormDialog(
      title: l.absenceNew,
      formKey: _form,
      validateExtra: () {
        final bad = _to.isBefore(_from);
        setState(() => _bad = bad);
        return !bad;
      },
      onSubmit: () => runAction(
        context,
        () => ref.read(absencesProvider.notifier).create(
          playerId: _playerId ?? ids.first,
          from: _from,
          to: _to,
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        ),
        success: l.absenceSaved,
      ),
      children: [
        PlayerPicker(label: l.absencePlayer, value: _playerId, onChanged: (v) => setState(() => _playerId = v)),
        formGap,
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
