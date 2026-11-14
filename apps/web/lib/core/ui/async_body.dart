import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_error.dart';
import '../../l10n/gen/app_localizations.dart';
import 'app_error_view.dart';
import 'empty_state.dart';

/// The four states every list screen has: loading, error (with retry),
/// empty, populated. Keeps previous data visible while refreshing.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyMessage,
    this.emptyAction,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  /// When it returns true for the data, [emptyMessage] is shown.
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    final data = value.value;
    if (data != null) {
      if (isEmpty?.call(data) ?? false) {
        return EmptyState(
          icon: Icons.inbox_outlined,
          title: emptyMessage ?? AppLocalizations.of(context).emptyTitle,
          action: emptyAction,
        );
      }
      return builder(context, data);
    }
    if (value.hasError) {
      return AppErrorView(error: AppError.of(value.error!), onRetry: onRetry);
    }
    return const LoadingView();
  }
}
