import 'package:material_ui/material_ui.dart';

import '../ui/kit.dart';

/// An icon button that shows a small spinner in place of its icon while it
/// works, and does nothing then: the shape of every export button.
class BusyIconButton extends StatelessWidget {
  const BusyIconButton({
    super.key,
    required this.icon,
    required this.busy,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final bool busy;
  final String tooltip;

  /// Null disables the button (offline, say); a busy button is disabled too.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: busy
        ? const SizedBox.square(
            dimension: HoopsSpace.lg,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    onPressed: busy ? null : onPressed,
  );
}

/// A snack bar on a messenger captured before an `await` (the screen may be
/// gone by then); nothing when there was none.
void showExportMessage(ScaffoldMessengerState? messenger, String text) =>
    messenger?.showSnackBar(SnackBar(content: Text(text)));
