import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/session/capabilities.dart';
import '../../../core/ui/app_error_view.dart';
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
        child: id == null ? EmptyView(message: l.meNoPlayer) : PlayerHub(key: ValueKey(id), playerId: id),
      ),
    );
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
    final ids = ref.watch(capabilitiesProvider).linkedPlayerIds.toList()..sort();
    if (ids.isEmpty) return EmptyView(message: l.myPlayersEmpty);
    final current = ids.contains(_selected) ? _selected! : ids.first;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
        child: Column(
          children: [
            if (ids.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 0),
                child: Row(
                  children: [
                    for (final id in ids)
                      Padding(
                        padding: const EdgeInsets.only(right: AppTokens.spaceSm),
                        child: ChoiceChip(
                          key: Key('child-$id'),
                          label: Text(ref.watch(playerNameProvider(id)) ?? id),
                          selected: id == current,
                          onSelected: (_) => setState(() => _selected = id),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: PlayerHub(key: ValueKey(current), playerId: current)),
          ],
        ),
      ),
    );
  }
}
