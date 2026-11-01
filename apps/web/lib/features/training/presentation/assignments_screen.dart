import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../application/training_providers.dart';
import 'assignment_widgets.dart';
import 'player_picker.dart';
import 'training_labels.dart';

/// Staff overview of assigned plans with progress counts.
class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return SubPage(
      title: l.assignmentsTitle,
      parentPath: '/training',
      child: Guarded(
        allowed: caps.canSeeModule,
        child: AsyncBody<AssignmentsView>(
          value: ref.watch(assignmentsProvider(null)),
          onRetry: () => ref.invalidate(assignmentsProvider(null)),
          isEmpty: (d) => d.assignments.isEmpty,
          emptyMessage: l.assignmentsEmpty,
          builder: (context, view) => ListView(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            children: [for (final a in view.assignments) AssignmentCard(assignment: a, view: view, onTap: () => context.go('/training/assignments/${a.id}'))],
          ),
        ),
      ),
    );
  }
}

String _targetText(AppLocalizations l, ath.PlanAssignment a, Map<String, String> teamNames, String? playerName) =>
    a.teamId != null ? l.assignmentTeamTarget(teamNames[a.teamId] ?? '—') : (playerName ?? l.assignmentPlayerTarget);

class AssignmentCard extends ConsumerWidget {
  const AssignmentCard({super.key, required this.assignment, required this.view, this.onTap});
  final ath.PlanAssignment assignment;
  final AssignmentsView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = assignment;
    final counts = view.countsFor(a.id);
    final names = ref.watch(teamNamesProvider);
    final playerName = a.playerId == null ? null : ref.watch(playerNameProvider(a.playerId!));
    return Card(
      child: ListTile(
        key: Key('assignment-${a.id}'),
        onTap: onTap,
        title: Text(a.plan.name),
        subtitle: Text(
          [
            _targetText(l, a, names, playerName),
            l.assignmentDue(fullDate(a.dueOn)),
            l.assignmentProgress(
              counts[ath.CompletionStatus.DONE] ?? 0,
              counts[ath.CompletionStatus.NOT_DONE] ?? 0,
              counts[ath.CompletionStatus.PARTIAL] ?? 0,
            ),
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Per-player progress of one assignment (staff may mark on behalf).
class AssignmentProgressScreen extends ConsumerWidget {
  const AssignmentProgressScreen({super.key, required this.assignmentId});
  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final value = ref.watch(assignmentsProvider(null));
    return SubPage(
      title: l.assignmentProgressTitle,
      parentPath: '/training/assignments',
      child: Guarded(
        allowed: caps.canSeeModule,
        child: AsyncBody<AssignmentsView>(
          value: value,
          onRetry: () => ref.invalidate(assignmentsProvider(null)),
          builder: (context, view) {
            final a = view.assignments.where((x) => x.id == assignmentId).firstOrNull;
            if (a == null) return const EmptyNotFound();
            return _Progress(assignment: a, view: view);
          },
        ),
      ),
    );
  }
}

class EmptyNotFound extends StatelessWidget {
  const EmptyNotFound({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(AppLocalizations.of(context).errorNotFound));
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.assignment, required this.view});
  final ath.PlanAssignment assignment;
  final AssignmentsView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = assignment;
    // Targets: the single player, or the team roster.
    final targets = <(String, String)>[];
    if (a.playerId != null) {
      targets.add((a.playerId!, ref.watch(playerNameProvider(a.playerId!)) ?? a.playerId!));
    } else if (a.teamId != null) {
      final roster = ref.watch(teamDetailProvider(a.teamId!)).value?.roster ?? const [];
      for (final p in roster) {
        targets.add((p.player.id, p.player.displayName));
      }
    }
    final caps = ref.watch(capabilitiesProvider);
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      children: [
        AssignmentCard(assignment: a, view: view),
        if (a.notes != null) Padding(padding: const EdgeInsets.all(AppTokens.spaceSm), child: Text(a.notes!)),
        for (final (id, name) in targets)
          Card(
            key: Key('progress-$id'),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppTokens.spaceXs),
                  CompletionControl(
                    assignmentId: a.id,
                    playerId: id,
                    completion: view.completionOf(a.id, id),
                    canMark: caps.canMarkCompletion(id),
                    scope: null,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppTokens.spaceMd),
        OutlinedButton.icon(
          key: const Key('assignment-delete'),
          icon: const Icon(Icons.delete_outline),
          label: Text(l.delete),
          onPressed: () async {
            if (!await confirmDialog(context, message: l.assignmentDeleteConfirm, confirmLabel: l.delete)) return;
            if (!context.mounted) return;
            final ok = await runAction(context, () => ref.read(assignmentsProvider(null).notifier).unassign(a.id));
            if (ok && context.mounted) context.go('/training/assignments');
          },
        ),
      ],
    );
  }
}
