import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../l10n/gen/app_localizations.dart';

const sitAndReachCode = 'SIT_AND_REACH';

/// How to read the unit of a test whose scale is not obvious. Today only the sit-and-reach (Catley scale, 20 cm is
/// where the toes are); nothing for any other test. [code] is the test type code.
class ScaleHint extends StatelessWidget {
  const ScaleHint({super.key, required this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    if (code != sitAndReachCode) return const SizedBox.shrink();
    final c = HoopsTokens.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: HoopsSpace.xs),
      child: Row(
        key: const Key('scale-hint-$sitAndReachCode'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.xs,
        children: [
          Icon(Icons.info_outline, size: 16, color: c.inkMuted),
          Expanded(
            child: Text(
              AppLocalizations.of(context).testHintSitAndReach,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
