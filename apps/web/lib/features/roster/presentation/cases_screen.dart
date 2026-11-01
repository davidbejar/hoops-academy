import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/roster_providers.dart';
import 'eligibility_widgets.dart';

/// Open eligibility cases: reason, player, invalidated team, resolve flows.
class CasesScreen extends ConsumerWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final cases = ref.watch(casesProvider);
    return SubPage(
      title: l.adminCases,
      parentPath: '/teams',
      child: AsyncBody<List<api.EligibilityCase>>(
        value: cases,
        onRetry: () => ref.invalidate(casesProvider),
        isEmpty: (d) => d.isEmpty,
        emptyMessage: l.casesEmpty,
        builder: (context, data) => ListView(
          children: [
            for (final c in data)
              _CaseCard(
                eligibilityCase: c,
                canResolve: caps.canResolveCase(c.team.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends ConsumerWidget {
  const _CaseCard({required this.eligibilityCase, required this.canResolve});
  final api.EligibilityCase eligibilityCase;
  final bool canResolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = eligibilityCase;
    final notifier = ref.read(casesProvider.notifier);
    return Card(
      key: Key('case-${c.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMd,
        vertical: AppTokens.spaceXs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.player.displayName, style: theme.textTheme.titleMedium),
            Text(l.caseTeam(c.team.name)),
            const SizedBox(height: AppTokens.spaceXs),
            InfoChip(
              c.reason.label(l),
              tone: ChipTone.bad,
              icon: Icons.warning_amber,
            ),
            if (canResolve)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceSm),
                child: Wrap(
                  spacing: AppTokens.spaceSm,
                  children: [
                    FilledButton(
                      key: Key('reassign-${c.id}'),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _ReassignDialog(eligibilityCase: c),
                      ),
                      child: Text(l.caseReassign),
                    ),
                    OutlinedButton(
                      key: Key('remove-${c.id}'),
                      onPressed: () => runAction(
                        context,
                        () => notifier.removeFromTeam(c),
                        success: l.caseResolved,
                      ),
                      child: Text(l.caseRemoveFromTeam),
                    ),
                    TextButton(
                      key: Key('dismiss-${c.id}'),
                      onPressed: () => runAction(
                        context,
                        () => notifier.dismiss(c),
                        success: l.caseResolved,
                      ),
                      child: Text(l.caseDismiss),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReassignDialog extends ConsumerStatefulWidget {
  const _ReassignDialog({required this.eligibilityCase});
  final api.EligibilityCase eligibilityCase;

  @override
  ConsumerState<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends ConsumerState<_ReassignDialog> {
  late final Future<List<api.EligibleTeam>> _teams = ref
      .read(casesProvider.notifier)
      .eligibleTeamsFor(widget.eligibilityCase);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.eligibilityCase;
    return AlertDialog(
      title: Text(l.caseReassignTitle(c.player.displayName)),
      content: SizedBox(
        width: 360,
        child: FutureBuilder<List<api.EligibleTeam>>(
          future: _teams,
          builder: (context, snap) {
            if (snap.hasError) return Text(AppErrorText.of(snap.error!, l));
            final teams = snap.data;
            if (teams == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final options = [
              for (final e in teams)
                if (e.team.id != c.team.id &&
                    e.eligibility.result != api.EligibilityResult.INELIGIBLE)
                  e,
            ];
            if (options.isEmpty) {
              return Text(
                l.playerNoEligibleTeams,
                key: const Key('no-eligible-teams'),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                Text(l.casePickTeam),
                for (final e in options)
                  ListTile(
                    key: Key('reassign-to-${e.team.id}'),
                    title: Text(e.team.displayLabel),
                    subtitle: EligibilityBadge(
                      result: e.eligibility.result,
                      playUpLevels: e.eligibility.playUpLevels ?? 0,
                    ),
                    onTap: () async {
                      final ok = await runAction(
                        context,
                        () => ref
                            .read(casesProvider.notifier)
                            .reassign(c, e.team.id),
                        success: l.caseResolved,
                      );
                      if (ok && context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}
