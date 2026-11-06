import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// A rounded square with an icon on a tone's container colour: the leading
/// mark of a [ListRow] (hub entries, audit entries) and of a stat tile.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.tone = HoopsTone.accent,
    this.size = HoopsSize.avatar,
  });

  final IconData icon;
  final HoopsTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = HoopsTokens.colorsOf(context).tone(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(HoopsRadius.sm),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, size: size * 0.5, color: colors.onContainer),
      ),
    );
  }
}
