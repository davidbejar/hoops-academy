import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// A key figure (KPI): big [value], its [label], an optional [caption]
/// (trend, period) and an [icon] in the [tone]'s colours.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.tone = HoopsTone.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;
  final HoopsTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final colors = c.tone(tone);
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      button: onTap != null,
      label: [label, value, ?caption].join(', '),
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoopsRadius.lg),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HoopsSpace.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.container,
                      borderRadius: BorderRadius.circular(HoopsRadius.sm),
                    ),
                    child: SizedBox.square(
                      dimension: HoopsSize.iconTile - 4,
                      child: Icon(icon, size: 22, color: colors.onContainer),
                    ),
                  ),
                  const SizedBox(height: HoopsSpace.gap),
                ],
                Text(value, style: HoopsType.statValue(text, c)),
                const SizedBox(height: HoopsSpace.xs),
                Text(
                  label,
                  style: text.labelLarge!.copyWith(
                    color: c.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: HoopsSpace.xs),
                  Text(
                    caption!,
                    style: text.bodySmall!.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
