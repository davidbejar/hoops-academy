import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/ui/actions.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/training_providers.dart';
import 'training_labels.dart';

/// DONE / PARTIAL / NOT_DONE marking for one (assignment, player). Without
/// [canMark] it only shows the current mark.
class CompletionControl extends ConsumerWidget {
  const CompletionControl({
    super.key,
    required this.assignmentId,
    required this.playerId,
    required this.completion,
    required this.canMark,
    required this.scope,
  });

  final String assignmentId;
  final String playerId;
  final ath.PlanCompletion? completion;
  final bool canMark;

  /// Family argument of the [assignmentsProvider] to refresh.
  final String? scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = completion?.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canMark)
          current == null
              ? Text(l.completionNone, style: theme.textTheme.bodySmall)
              : InfoChip(current.label(l), tone: current.tone, icon: current.icon)
        else
          Wrap(
            spacing: AppTokens.spaceSm,
            children: [
              for (final s in completionChoices)
                ChoiceChip(
                  key: Key('comp-$assignmentId-$playerId-${s.name}'),
                  avatar: Icon(s.icon, size: 18),
                  label: Text(s.label(l)),
                  selected: current == s,
                  onSelected: (_) async {
                    final comment = await noteDialog(
                      context,
                      title: s.label(l),
                      confirmLabel: l.completionMark,
                      label: l.completionComment,
                    );
                    if (comment == null || !context.mounted) return;
                    await runAction(
                      context,
                      () => ref.read(assignmentsProvider(scope).notifier).record(
                        assignmentId,
                        playerId,
                        s,
                        comment: comment.isEmpty ? null : comment,
                      ),
                      success: l.completionSaved,
                    );
                  },
                ),
            ],
          ),
        if (completion?.comment != null && completion!.comment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spaceXs),
            child: Text(completion!.comment!, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
