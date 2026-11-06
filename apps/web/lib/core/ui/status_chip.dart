import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Small coloured label for a state: role, availability, match state,
/// injury, approval. The [tone] carries the meaning; never colour alone, the
/// [label] always says it (and the optional [icon] repeats it).
class StatusChip extends StatelessWidget {
  const StatusChip(
    this.label, {
    super.key,
    this.tone = HoopsTone.neutral,
    this.icon,
    this.dot = false,
  });

  final String label;
  final HoopsTone tone;
  final IconData? icon;

  /// A leading dot for live states (a match in progress).
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final colors = HoopsTokens.colorsOf(context).tone(tone);
    final style = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: colors.onContainer, fontWeight: FontWeight.w700);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(HoopsRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HoopsSpace.sm,
          vertical: HoopsSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                key: const Key('status-chip-dot'),
                width: HoopsSpace.sm,
                height: HoopsSpace.sm,
                decoration: BoxDecoration(
                  color: colors.foreground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: HoopsSpace.xs + 2),
            ],
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.onContainer),
              const SizedBox(width: HoopsSpace.xs),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}
