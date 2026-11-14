import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../health/presentation/player_health_view.dart';
import '../../roster/presentation/preferred_jersey.dart';
import '../../training/application/training_providers.dart';
import '../../training/presentation/assignment_widgets.dart';
import '../../training/presentation/assignments_screen.dart'
    show AssignmentCard;
import '../../training/presentation/player_picker.dart' show playerNameProvider;
import '../../training/presentation/training_screen.dart' show SessionTile;

enum HubTab { training, plans, health }

/// Everything about one player for the player themself or a guardian:
/// season stats link, upcoming trainings, assigned plans with completion
/// and the health views.
class PlayerHub extends ConsumerStatefulWidget {
  const PlayerHub({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<PlayerHub> createState() => _PlayerHubState();
}

class _PlayerHubState extends ConsumerState<PlayerHub> {
  HubTab _tab = HubTab.training;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final id = widget.playerId;
    final labels = {
      HubTab.training: l.meTabTraining,
      HubTab.plans: l.meTabPlans,
      HubTab.health: l.healthTitle,
    };
    return PageBody(
      header: PageHeader(
        title: ref.watch(playerNameProvider(id)) ?? '',
        actions: [
          OutlinedButton.icon(
            key: const Key('hub-season-stats'),
            icon: const Icon(Icons.bar_chart),
            label: Text(l.meSeasonStats),
            onPressed: () => context.go('/matches/stats/$id'),
          ),
        ],
      ),
      children: [
        PreferredJerseyCard(playerId: id),
        Wrap(
          spacing: HoopsSpace.sm,
          runSpacing: HoopsSpace.sm,
          children: [
            for (final t in HubTab.values)
              ChoiceChip(
                key: Key('hub-tab-${t.name}'),
                label: Text(labels[t]!),
                selected: _tab == t,
                onSelected: (_) => setState(() => _tab = t),
              ),
          ],
        ),
        switch (_tab) {
          HubTab.training => _Upcoming(playerId: id),
          HubTab.plans => _Plans(playerId: id),
          HubTab.health => PlayerHealthView(playerId: id),
        },
      ],
    );
  }
}

class _Upcoming extends ConsumerWidget {
  const _Upcoming({required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final names = ref.watch(teamNamesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.gap,
      children: [
        Text(l.meUpcoming, style: Theme.of(context).textTheme.titleLarge),
        AsyncBody<List<ath.TrainingSession>>(
          value: ref.watch(upcomingSessionsProvider(playerId)),
          onRetry: () => ref.invalidate(upcomingSessionsProvider(playerId)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.meNoUpcoming,
          builder: (context, data) => Column(
            spacing: HoopsSpace.gap,
            children: [
              for (final s in data)
                SessionTile(session: s, teamName: names[s.teamId]),
            ],
          ),
        ),
        if (caps.canFileAbsenceFor(playerId))
          TextButton.icon(
            key: const Key('hub-absences'),
            icon: const Icon(Icons.event_busy_outlined),
            label: Text(l.trainingMenuAbsences),
            onPressed: () => context.go('/training/absences'),
          ),
      ],
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans({required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return AsyncBody<AssignmentsView>(
      value: ref.watch(assignmentsProvider(playerId)),
      onRetry: () => ref.invalidate(assignmentsProvider(playerId)),
      isEmpty: (d) => d.assignments.isEmpty,
      emptyMessage: l.mePlansEmpty,
      builder: (context, view) => Column(
        spacing: HoopsSpace.gap,
        children: [
          for (final a in view.assignments)
            Column(
              key: Key('hub-assignment-${a.id}'),
              children: [
                AssignmentCard(assignment: a, view: view),
                Padding(
                  padding: const EdgeInsets.only(left: HoopsSpace.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CompletionControl(
                      assignmentId: a.id,
                      playerId: playerId,
                      completion: view.completionOf(a.id, playerId),
                      canMark: caps.canMarkCompletion(playerId),
                      scope: playerId,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
