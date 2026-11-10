import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// A titled block of a page: the landing's card (surface, hairline border,
/// large radius) with an optional header row of [title], [subtitle] and
/// [actions].
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.padding,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  /// Inner padding; defaults to 16 on phones and 24 from tablets up.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final compact = WidthClass.of(context).isCompact;
    final hasHeader = title != null || actions.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(HoopsRadius.lg),
        border: Border.all(color: c.border),
      ),
      // Transparent Material: list tiles and inks in the body need one.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding:
              padding ??
              EdgeInsets.all(compact ? HoopsSpace.md + 4 : HoopsSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasHeader) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Semantics(
                              header: true,
                              child: Text(
                                title!,
                                style: text.titleMedium!.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: HoopsSpace.xxs),
                            Text(subtitle!, style: text.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
                const SizedBox(height: HoopsSpace.gap),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
