import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/roster_providers.dart';
import '../application/roster_rights.dart';
import 'jersey_dialog.dart' show jerseyPattern;

/// The number a player prefers, with the edit button for those who may set it.
class PreferredJerseyCard extends ConsumerWidget {
  const PreferredJerseyCard({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final player = ref.watch(playerDetailProvider(playerId)).value;
    if (player == null) return const SizedBox.shrink();
    final number = player.preferredJerseyNumber;
    final wish = caps.isJerseyWish(playerId);
    final muted = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: HoopsTokens.colorsOf(context).inkMuted);
    return SectionCard(
      key: const Key('preferred-jersey'),
      title: wish ? l.playerPreferredJerseyWish : l.playerPreferredJersey,
      actions: [
        if (caps.canSetPreferredJersey(playerId))
          IconButton(
            key: const Key('preferred-jersey-edit'),
            tooltip: l.playerPreferredJerseyEdit,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => PreferredJerseyDialog(
                playerId: playerId,
                current: number,
                wish: wish,
              ),
            ),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.xs,
        children: [
          number == null
              ? Text(
                  l.playerPreferredJerseyNone,
                  key: const Key('preferred-jersey-none'),
                  style: muted,
                )
              : Text(
                  number,
                  key: const Key('preferred-jersey-value'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
          if (wish)
            Text(
              l.playerPreferredJerseyWishHint,
              key: const Key('preferred-jersey-wish-hint'),
              style: muted,
            ),
        ],
      ),
    );
  }
}

/// Sets or removes the preferred number (`^[0-9]{1,2}$`); empty removes it (ADR-0032).
class PreferredJerseyDialog extends ConsumerStatefulWidget {
  const PreferredJerseyDialog({
    super.key,
    required this.playerId,
    required this.current,
    required this.wish,
  });
  final String playerId;
  final String? current;
  final bool wish;

  @override
  ConsumerState<PreferredJerseyDialog> createState() =>
      _PreferredJerseyDialogState();
}

class _PreferredJerseyDialogState extends ConsumerState<PreferredJerseyDialog> {
  final _form = GlobalKey<FormState>();
  late final _number = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: widget.wish
          ? l.playerPreferredJerseyWish
          : l.playerPreferredJerseyEdit,
      formKey: _form,
      onSubmit: () {
        final text = _number.text.trim();
        return runAction(
          context,
          () => ref
              .read(playerDetailProvider(widget.playerId).notifier)
              .setPreferredJersey(text.isEmpty ? null : text),
          success: l.saved,
        );
      },
      children: [
        TextFormField(
          key: const Key('preferred-jersey-field'),
          controller: _number,
          maxLength: 2,
          keyboardType: TextInputType.number,
          validator: (v) {
            final t = (v ?? '').trim();
            return t.isEmpty || jerseyPattern.hasMatch(t)
                ? null
                : l.fieldInvalidNumber;
          },
          decoration: InputDecoration(
            labelText: l.rosterJersey,
            helperText: widget.wish
                ? l.playerPreferredJerseyWishHint
                : l.rosterJerseyEmptyHint,
          ),
        ),
      ],
    );
  }
}
