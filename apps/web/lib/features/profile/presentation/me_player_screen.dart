import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/capabilities.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../training/presentation/player_picker.dart' show playerNameProvider;
import 'player_hub.dart';

/// "Me" for a PLAYER.
class MePlayerScreen extends ConsumerWidget {
  const MePlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final id = ref.watch(capabilitiesProvider).ownPlayerId;
    return id == null
        ? EmptyState(icon: Icons.person_off_outlined, title: l.meNoPlayer)
        : PlayerHub(key: ValueKey(id), playerId: id);
  }
}

/// "My players" for a PARENT: child switcher over the linked players.
class MyPlayersView extends ConsumerStatefulWidget {
  const MyPlayersView({super.key});

  @override
  ConsumerState<MyPlayersView> createState() => _MyPlayersViewState();
}

class _MyPlayersViewState extends ConsumerState<MyPlayersView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ids = ref.watch(capabilitiesProvider).linkedPlayerIds.toList()
      ..sort();
    if (ids.isEmpty) {
      return EmptyState(
        icon: Icons.family_restroom_outlined,
        title: l.myPlayersEmpty,
      );
    }
    final current = ids.contains(_selected) ? _selected! : ids.first;
    return Column(
      children: [
        if (ids.length > 1)
          ContentFrame(
            child: Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: HoopsSpace.sm,
                  children: [
                    for (final id in ids)
                      ChoiceChip(
                        key: Key('child-$id'),
                        label: Text(ref.watch(playerNameProvider(id)) ?? id),
                        selected: id == current,
                        onSelected: (_) => setState(() => _selected = id),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: PlayerHub(key: ValueKey(current), playerId: current),
        ),
      ],
    );
  }
}
