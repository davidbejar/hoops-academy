import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/kit.dart';
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
        builder: (context, data) => PageBody(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: HoopsSpace.gap,
              children: [
                for (final c in data)
                  _CaseCard(
                    eligibilityCase: c,
                    canResolve: caps.canResolveCase(c.team.id),
                  ),
              ],
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
    final c = eligibilityCase;
    final notifier = ref.read(casesProvider.notifier);
    return SectionCard(
      key: Key('case-${c.id}'),
      title: c.player.displayName,
      subtitle: l.caseTeam(c.team.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            c.reason.label(l),
            tone: HoopsTone.danger,
            icon: Icons.warning_amber,
          ),
          if (canResolve)
            Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.md),
              child: Wrap(
                spacing: HoopsSpace.sm,
                runSpacing: HoopsSpace.sm,
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
  /// The teams the player can move to: not the current one, not ineligible.
  late final Future<List<api.EligibleTeam>> _options = ref
      .read(casesProvider.notifier)
      .eligibleTeamsFor(widget.eligibilityCase)
      .then(
        (teams) => [
          for (final e in teams)
            if (e.team.id != widget.eligibilityCase.team.id &&
                e.eligibility.result != api.EligibilityResult.INELIGIBLE)
              e,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.eligibilityCase;
    return PickerDialog<api.EligibleTeam>(
      title: l.caseReassignTitle(c.player.displayName),
      future: _options,
      intro: l.casePickTeam,
      emptyText: l.playerNoEligibleTeams,
      emptyKey: const Key('no-eligible-teams'),
      itemBuilder: (context, e) => ListTile(
        key: Key('reassign-to-${e.team.id}'),
        title: Text(e.team.displayLabel),
        subtitle: EligibilityBadge(
          result: e.eligibility.result,
          playUpLevels: e.eligibility.playUpLevels ?? 0,
        ),
        onTap: () async {
          final ok = await runAction(
            context,
            () => ref.read(casesProvider.notifier).reassign(c, e.team.id),
            success: l.caseResolved,
          );
          if (ok && context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}
