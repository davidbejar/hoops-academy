import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// The title block of a page: optional [eyebrow] (season, team), a heavy
/// [title], a [subtitle] and the page's [actions] (beside the title from
/// tablets up, under it on phones).
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final compact = WidthClass.of(context).isCompact;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, style: HoopsType.eyebrow(text, c)),
          const SizedBox(height: HoopsSpace.xs + 2),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: compact ? text.headlineSmall : text.headlineMedium,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: HoopsSpace.xs),
          Text(subtitle!, style: text.bodyMedium!.copyWith(color: c.inkMuted)),
        ],
      ],
    );
    if (actions.isEmpty) return heading;
    final buttons = Wrap(
      spacing: HoopsSpace.sm,
      runSpacing: HoopsSpace.sm,
      children: actions,
    );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              heading,
              const SizedBox(height: HoopsSpace.md),
              buttons,
            ],
          )
        : Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: HoopsSpace.md),
              buttons,
            ],
          );
  }
}

/// Centres [child] in a column of at most [maxWidth] with the device's
/// gutter (16 / 24 / 32 px for phones / tablets / desktops). A narrower child
/// is stretched to the column's width.
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = WidthClass.readingMax,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = WidthClass.of(context).gutter;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + 2 * gutter),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// A scrolling page: [header] and [children] (sections) separated by the
/// device's section gap, inside a [ContentFrame].
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    this.header,
    required this.children,
    this.maxWidth = WidthClass.readingMax,
  });

  final Widget? header;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = WidthClass.of(context);
    final sections = [?header, ...children];
    return ListView(
      padding: EdgeInsets.symmetric(vertical: width.sectionGap),
      children: [
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) SizedBox(height: width.sectionGap),
          ContentFrame(maxWidth: maxWidth, child: section),
        ],
      ],
    );
  }
}
