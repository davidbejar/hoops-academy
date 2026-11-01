import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';

/// Name of a player by id (empty until loaded).
final playerNameProvider = Provider.family<String?, String>(
  (ref, id) => ref.watch(playerDetailProvider(id)).value?.displayName,
);

/// Players the caller may act for: staff all, PARENT linked, PLAYER self.
final selectablePlayerIdsProvider = Provider<List<String>>((ref) {
  final caps = ref.watch(capabilitiesProvider);
  if (caps.canSeeModule) {
    return [for (final p in ref.watch(playersProvider).value ?? const <api.Player>[]) p.id];
  }
  return [...caps.linkedPlayerIds, if (caps.ownPlayerId != null) caps.ownPlayerId!];
});

class PlayerPicker extends ConsumerWidget {
  const PlayerPicker({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ids = ref.watch(selectablePlayerIdsProvider);
    return DropdownButtonFormField<String>(
      key: const Key('player-picker'),
      initialValue: value ?? (ids.length == 1 ? ids.first : null),
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [for (final id in ids) DropdownMenuItem(value: id, child: Text(ref.watch(playerNameProvider(id)) ?? id))],
      validator: (v) => (v ?? (ids.length == 1 ? ids.first : null)) == null ? l.fieldRequired : null,
      onChanged: onChanged,
    );
  }
}
