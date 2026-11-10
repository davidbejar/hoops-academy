import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/roster_providers.dart';

/// One or two digits, like the server's `^[0-9]{1,2}$`.
final jerseyPattern = RegExp(r'^[0-9]{1,2}$');

/// The numbers a team can offer: 0 to 99.
const _numbers = 100;

/// Sets or removes a player's jersey number on a team. It shows the numbers taken with their players and the free
/// ones; a taken number is refused with the holder's name. An empty value is saved as null, which the repository
/// sends in `clear` (ADR-0032). A failure keeps the dialog open; after a clash the list is read again and names
/// whoever holds the number now. [notice] explains why the dialog opened by itself (nothing could be assigned).
class JerseyDialog extends ConsumerStatefulWidget {
  const JerseyDialog({
    super.key,
    required this.teamId,
    required this.playerId,
    required this.current,
    this.notice,
  });
  final String teamId;
  final String playerId;
  final String? current;
  final String? notice;

  @override
  ConsumerState<JerseyDialog> createState() => _JerseyDialogState();
}

class _JerseyDialogState extends ConsumerState<JerseyDialog> {
  final _form = GlobalKey<FormState>();
  late final _jersey = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    _jersey.dispose();
    super.dispose();
  }

  /// What other players wear, from the latest list.
  Map<String, String> _heldByOthers() => {
    for (final t
        in ref.read(teamJerseyNumbersProvider(widget.teamId)).value ??
            const <api.TakenJerseyNumber>[])
      if (t.player.id != widget.playerId) t.jerseyNumber: t.player.displayName,
  };

  String? _validate(AppLocalizations l, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!jerseyPattern.hasMatch(text)) return l.fieldInvalidNumber;
    final holder = _heldByOthers()[text];
    return holder == null ? null : l.jerseyTakenBy(text, holder);
  }

  Future<bool> _save(AppLocalizations l) async {
    final text = _jersey.text.trim();
    final ok = await runAction(
      context,
      () => ref
          .read(teamDetailProvider(widget.teamId).notifier)
          .setJersey(widget.playerId, text.isEmpty ? null : text),
      success: l.saved,
    );
    if (!ok) {
      // A clash the list did not show yet: read it again and name the holder.
      ref.invalidate(teamJerseyNumbersProvider(widget.teamId));
      try {
        await ref.read(teamJerseyNumbersProvider(widget.teamId).future);
      } on Object {
        // the field keeps working without the list
      }
      if (mounted) _form.currentState?.validate();
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final taken =
        ref.watch(teamJerseyNumbersProvider(widget.teamId)).value ??
        const <api.TakenJerseyNumber>[];
    final others = [
      for (final t in taken)
        if (t.player.id != widget.playerId) t,
    ];
    final occupied = {for (final t in others) t.jerseyNumber};
    return FormDialog(
      title: l.rosterJerseyEdit,
      formKey: _form,
      onSubmit: () => _save(l),
      children: [
        if (widget.notice != null) ...[
          Text(widget.notice!, key: const Key('jersey-notice')),
          formGap,
        ],
        TextFormField(
          key: const Key('jersey-field'),
          controller: _jersey,
          maxLength: 2,
          keyboardType: TextInputType.number,
          validator: (v) => _validate(l, v),
          decoration: InputDecoration(
            labelText: l.rosterJersey,
            helperText: l.rosterJerseyEmptyHint,
          ),
        ),
        if (others.isNotEmpty) ...[
          formGap,
          Text(
            l.jerseyTakenTitle,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: HoopsSpace.xs),
          Wrap(
            spacing: HoopsSpace.xs,
            runSpacing: HoopsSpace.xs,
            children: [
              for (final t in others)
                StatusChip(
                  '${t.jerseyNumber} · ${t.player.displayName}',
                  key: Key('jersey-taken-${t.player.id}'),
                ),
            ],
          ),
        ],
        formGap,
        Text(l.jerseyFreeTitle, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: HoopsSpace.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 132),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: HoopsSpace.xs,
              runSpacing: HoopsSpace.xs,
              children: [
                for (var n = 0; n < _numbers; n++)
                  if (!occupied.contains('$n'))
                    ActionChip(
                      key: Key('jersey-free-$n'),
                      label: Text('$n'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _jersey.text = '$n'),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The sentence for the rule that chose the number of a new assignment.
String jerseyRuleText(AppLocalizations l, api.AssignedTeamPlayer assigned) {
  final number = assigned.jerseyNumber ?? '';
  return switch (assigned.jerseySource) {
    api.JerseySource.REQUESTED => l.jerseyRuleRequested(number),
    api.JerseySource.PREFERRED => l.jerseyRulePreferred(number),
    api.JerseySource.PREVIOUS => l.jerseyRulePrevious(number),
    _ => l.jerseyRuleNone,
  };
}

/// After an assignment: says which rule chose the number. When none could be given it opens [JerseyDialog] at once
/// so the number is picked now.
Future<void> showAssignmentOutcome(
  BuildContext context,
  api.AssignedTeamPlayer assigned,
) {
  final l = AppLocalizations.of(context);
  final text = jerseyRuleText(l, assigned);
  if (assigned.jerseySource == api.JerseySource.NONE) {
    return showDialog<bool>(
      context: context,
      builder: (_) => JerseyDialog(
        teamId: assigned.teamId,
        playerId: assigned.player.id,
        current: null,
        notice: text,
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('assignment-outcome'),
      title: Text(l.rosterAssigned),
      content: Text(text),
      actions: [
        FilledButton(
          key: const Key('assignment-outcome-close'),
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.close),
        ),
      ],
    ),
  );
}
