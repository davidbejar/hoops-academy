import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';

/// Full-width strip under the app bar (offline, demo mode, update ready) or
/// at the top of a page. Announced to screen readers when it appears.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.tone = HoopsTone.accent,
    this.icon,
    this.action,
  });

  final String message;
  final HoopsTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = HoopsTokens.colorsOf(context).tone(tone);
    final gutter = WidthClass.of(context).gutter;
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.container),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            HoopsSpace.sm,
            action == null ? gutter : HoopsSpace.sm,
            HoopsSpace.sm,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.onContainer),
                const SizedBox(width: HoopsSpace.sm + 2),
              ],
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: colors.onContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null)
                TextButtonTheme(
                  data: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onContainer,
                    ),
                  ),
                  child: action!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
