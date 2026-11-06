import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// A row of a list on its own card: leading avatar or icon, title,
/// subtitle, optional [details] under them (status chips, actions) and a
/// trailing widget. Tappable rows show a chevron unless they bring their own
/// [trailing].
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.details,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Under the title and subtitle, in the text column: chips that would
  /// squeeze the title on a phone if they sat in [trailing].
  final Widget? details;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HoopsRadius.lg),
      side: BorderSide(color: c.border),
    );
    final end =
        trailing ??
        (onTap == null ? null : Icon(Icons.chevron_right, color: c.inkMuted));
    return Material(
      color: c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HoopsSpace.md,
              vertical: HoopsSpace.gap,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: HoopsSpace.gap),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: text.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: HoopsSpace.xxs),
                        Text(
                          subtitle!,
                          style: text.bodyMedium!.copyWith(color: c.inkMuted),
                        ),
                      ],
                      if (details != null) ...[
                        const SizedBox(height: HoopsSpace.sm),
                        details!,
                      ],
                    ],
                  ),
                ),
                if (end != null) ...[const SizedBox(width: HoopsSpace.sm), end],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round avatar with up to two initials of [name], or [image] when given
/// (an academy logo, a player photo).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = HoopsSize.avatar,
    this.tone = HoopsTone.accent,
    this.image,
  });

  final String name;
  final double size;
  final HoopsTone tone;
  final ImageProvider? image;

  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.single;
      return word.substring(0, word.length.clamp(1, 2)).toUpperCase();
    }
    return (words.first[0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = HoopsTokens.colorsOf(context).tone(tone);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.container,
      foregroundColor: colors.onContainer,
      foregroundImage: image,
      child: Text(
        initials(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
