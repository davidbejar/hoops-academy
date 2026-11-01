import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../errors/app_error.dart';

extension AppErrorMessage on AppError {
  /// Localised, user-facing text for this error (never raw server text).
  String message(AppLocalizations l) => switch (kind) {
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              error.message(l),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (error.traceId != null) ...[
              const SizedBox(height: AppTokens.spaceSm),
              Text(
                l.errorReference(error.traceId!),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spaceMd),
              FilledButton(
                key: const Key('retry-button'),
                onPressed: onRetry,
                child: Text(l.retry),
              ),
            ],
          ],
        ),
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Text(
          message ?? l.emptyTitle,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
