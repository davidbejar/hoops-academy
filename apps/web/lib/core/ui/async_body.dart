import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_error.dart';
import '../../l10n/gen/app_localizations.dart';
import '../design/tokens.dart';
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

/// [AsyncBody] for a block inside a scrolling page or a card (WEB-05): a
/// compact spinner, the mapped error message (with [failedLabel] in front)
/// and a retry button, or a muted [emptyMessage]. Data stays on screen while a
/// refresh fails. [hideWhen] takes the failures the block should not show at
/// all (a coach without the right to see it, say).
///
/// The keys are the ones tests find the states by; the retry button is
/// `retry-button` like the page-level view unless [retryKey] says otherwise.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyMessage,
    this.failedLabel,
    this.hideWhen,
    this.loadingKey,
    this.errorKey,
    this.retryKey = const Key('retry-button'),
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;
  final String? failedLabel;
  final bool Function(AppError error)? hideWhen;
  final Key? loadingKey;
  final Key? errorKey;
  final Key retryKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = value.value;
    if (data != null) {
      if (isEmpty?.call(data) ?? false) {
        return Text(
          emptyMessage ?? l.emptyTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
      return builder(context, data);
    }
    if (value.hasError) {
      final error = AppError.of(value.error!);
      if (hideWhen?.call(error) ?? false) return const SizedBox.shrink();
      final message = error.message(l);
      return Column(
        key: errorKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.sm,
        children: [
          Text(failedLabel == null ? message : '$failedLabel · $message'),
          OutlinedButton(
            key: retryKey,
            onPressed: onRetry,
            child: Text(l.retry),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(HoopsSpace.md),
      child: Center(child: CircularProgressIndicator(key: loadingKey)),
    );
  }
}
