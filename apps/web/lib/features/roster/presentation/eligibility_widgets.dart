import 'package:material_ui/material_ui.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/labels.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Result of an eligibility check: ELIGIBLE / play-up badge / ineligible
/// with the reasons. Shared by the roster, player detail and cases flows.
class EligibilityPanel extends StatelessWidget {
  const EligibilityPanel({super.key, required this.check});

  final api.EligibilityCheck check;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    return Column(
      key: const Key('eligibility-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.xs,
      children: [
        EligibilityBadge(
          result: check.result,
          playUpLevels: check.playUpLevels ?? 0,
        ),
        if (check.result == api.EligibilityResult.INELIGIBLE)
          for (final r in check.reasons)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: HoopsSpace.xs,
              children: [
                Icon(
                  Icons.block,
                  size: HoopsSpace.md,
                  color: c.danger.foreground,
                ),
                Expanded(child: Text(r.label(l), key: Key('reason-${r.name}'))),
              ],
            ),
      ],
    );
  }
}

class EligibilityBadge extends StatelessWidget {
  const EligibilityBadge({
    super.key,
    required this.result,
    this.playUpLevels = 0,
  });

  final api.EligibilityResult result;
  final int playUpLevels;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (result == api.EligibilityResult.PLAY_UP) {
      return StatusChip(
        l.eligibilityPlayUp(playUpLevels.toString()),
        tone: HoopsTone.warning,
        icon: Icons.trending_up,
      );
    }
    if (result == api.EligibilityResult.INELIGIBLE) {
      return StatusChip(
        l.eligibilityIneligible,
        tone: HoopsTone.danger,
        icon: Icons.block,
      );
    }
    return StatusChip(
      l.eligibilityEligible,
      tone: HoopsTone.success,
      icon: Icons.check_circle_outline,
    );
  }
}

/// Small "+n" marker next to a rostered player who plays up.
class PlayUpBadge extends StatelessWidget {
  const PlayUpBadge({super.key, required this.levels});
  final int levels;

  @override
  Widget build(BuildContext context) => StatusChip(
    AppLocalizations.of(context).playUpBadge(levels.toString()),
    tone: HoopsTone.warning,
    icon: Icons.trending_up,
  );
}

extension TeamLabel on api.Team {
  String get displayLabel =>
      alias == null || alias!.isEmpty ? name : '$name ($alias)';
}
