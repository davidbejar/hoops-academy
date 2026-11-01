import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../errors/app_error.dart';
import 'app_error_view.dart';

/// Sub-page inside the shell: its own title bar with back button, content
/// capped to the design's max width and centred on wide screens.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.parentPath,
    required this.child,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;

  /// Where the back arrow goes (routes are flat `go`, not a push stack).
  final String parentPath;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        key: const Key('back-button'),
        icon: const Icon(Icons.arrow_back),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.go(parentPath),
      ),
      title: Text(title),
      actions: actions,
      primary: false,
    ),
    floatingActionButton: floatingActionButton,
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
        child: child,
      ),
    ),
  );
}

/// Small coloured label (status, play-up, read-only...).
class InfoChip extends StatelessWidget {
  const InfoChip(
    this.label, {
    super.key,
    this.tone = ChipTone.neutral,
    this.icon,
  });

  final String label;
  final ChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      ChipTone.good => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ChipTone.warn => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ChipTone.bad => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSm,
        vertical: AppTokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppTokens.spaceXs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChipTone { neutral, good, warn, bad }

/// Per-route capability check on top of the destination guard: shows the
/// localized "not allowed" state instead of a screen the role cannot use.
class Guarded extends StatelessWidget {
  const Guarded({super.key, required this.allowed, required this.child});

  final bool allowed;
  final Widget child;

  @override
  Widget build(BuildContext context) => allowed
      ? child
      : const AppErrorView(
          key: Key('forbidden'),
          error: AppError(kind: AppErrorKind.forbidden),
        );
}
