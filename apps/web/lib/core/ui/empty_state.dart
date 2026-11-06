import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Nothing to show yet (or an error): an icon tile in the [tone]'s colours,
/// a [title], an optional [message] and a call to [action].
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tone = HoopsTone.accent,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final HoopsTone tone;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final colors = c.tone(tone);
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(HoopsSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.container,
                  borderRadius: BorderRadius.circular(HoopsRadius.lg),
                ),
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(
                    icon,
                    size: 30,
                    color: tone == HoopsTone.accent
                        ? c.brand
                        : colors.foreground,
                  ),
                ),
              ),
              const SizedBox(height: HoopsSpace.md + 4),
              Text(title, textAlign: TextAlign.center, style: text.titleLarge),
              if (message != null) ...[
                const SizedBox(height: HoopsSpace.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium!.copyWith(color: c.inkMuted),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: HoopsSpace.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
