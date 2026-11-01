import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_error.dart';
import 'app_error_view.dart';

/// Seam over `loadLibrary()` so widget tests can make deferred loading
/// synchronous (the real thing completes in real time, outside FakeAsync).
final libraryLoaderProvider =
    Provider<Future<void> Function(Future<void> Function() load)>(
      (ref) =>
          (load) => load(),
    );

/// Loads a deferred library, then builds its screen.
///
/// ```dart
/// import '.../teams_screen.dart' deferred as teams;
/// DeferredScreen(load: teams.loadLibrary, builder: (_) => teams.TeamsScreen())
/// ```
class DeferredScreen extends ConsumerStatefulWidget {
  const DeferredScreen({super.key, required this.load, required this.builder});

  final Future<void> Function() load;
  final WidgetBuilder builder;

  @override
  ConsumerState<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends ConsumerState<DeferredScreen> {
  late Future<void> _loading = _start();

  Future<void> _start() => ref.read(libraryLoaderProvider)(widget.load);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return AppErrorView(
          error: const AppError(kind: AppErrorKind.network),
          onRetry: () => setState(() => _loading = _start()),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingView();
      }
      return widget.builder(context);
    },
  );
}
