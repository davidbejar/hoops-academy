import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens.dart';
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
        constraints: const BoxConstraints(maxWidth: WidthClass.readingMax),
        child: child,
      ),
    ),
  );
}

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
