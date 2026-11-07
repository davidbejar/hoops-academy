import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../design/tokens.dart';
import '../errors/app_error.dart';
import 'empty_state.dart';

extension AppErrorMessage on AppError {
  /// Localised, user-facing text for this error (never raw server text).
  String message(AppLocalizations l) =>
      code == 'SEASON_ENDED' ? l.errorSeasonEnded : _byKind(l);

  String _byKind(AppLocalizations l) => switch (kind) {
    AppErrorKind.network => l.errorNetwork,
    AppErrorKind.timeout => l.errorTimeout,
    AppErrorKind.unauthorized => l.errorUnauthorized,
    AppErrorKind.forbidden => l.errorForbidden,
    AppErrorKind.notFound => l.errorNotFound,
    AppErrorKind.conflict => l.errorConflict,
    AppErrorKind.validation => l.errorValidation,
    AppErrorKind.server => l.errorServer,
    AppErrorKind.unknown => l.errorUnknown,
  };
}

/// Error state with optional retry. Shows the trace id so support can find it.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.error, this.onRetry});

  final AppError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.error_outline,
      tone: HoopsTone.danger,
      title: error.message(l),
      message: error.traceId == null ? null : l.errorReference(error.traceId!),
      action: onRetry == null
          ? null
          : FilledButton(
              key: const Key('retry-button'),
              onPressed: onRetry,
              child: Text(l.retry),
            ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.inbox_outlined,
    title: message ?? AppLocalizations.of(context).emptyTitle,
  );
}
