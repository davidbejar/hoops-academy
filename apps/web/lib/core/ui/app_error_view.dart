import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../design/tokens.dart';
import '../errors/app_error.dart';
import 'empty_state.dart';

extension AppErrorMessage on AppError {
  /// Localised, user-facing text for this error (never raw server text): the
  /// services' business codes in the user's words, 501 as "not available
  /// yet", anything else the generic text of its kind.
  String message(AppLocalizations l) =>
      _byCode(l) ??
      (status == 501 ? l.financeNotYetAvailable : null) ??
      _byKind(l);

  /// The one table of business codes (Problem+JSON `code`). A screen that
  /// needs other words for a code in its context passes its own `errorText`
  /// (members do for two codes) and falls back to this.
  String? _byCode(AppLocalizations l) => switch (code) {
    'SEASON_ENDED' => l.errorSeasonEnded,
    'ROLLOVER_TARGET_NOT_EMPTY' => l.rolloverErrorTargetNotEmpty,
    // finance
    'DUE_NOT_OPEN' => l.financeErrorDueNotOpen,
    'CURRENCY_LOCKED' => l.financeErrorCurrencyLocked,
    'UNKNOWN_CURRENCY' => l.financeErrorUnknownCurrency,
    'CURRENCY_NOT_SET' => l.financeErrorCurrencyNotSet,
    'FEE_PLAN_HAS_DUES' => l.financeErrorFeePlanHasDues,
    'FEE_PLAN_ARCHIVED' => l.financeErrorFeePlanArchived,
    'PAID_ON_IN_FUTURE' => l.financeErrorPaidOnInFuture,
    'PAYMENT_ALREADY_VOIDED' => l.financeErrorPaymentAlreadyVoided,
    'PERIOD_OUTSIDE_PLAN' => l.financeErrorPeriodOutsidePlan,
    'PERIOD_OUTSIDE_SEASON' => l.financeErrorPeriodOutsideSeason,
    'TOO_MANY_DUES' => l.financeErrorTooManyDues,
    'TEAM_NOT_IN_SEASON' => l.financeErrorTeamNotInSeason,
    'CONCURRENT_MODIFICATION' => l.financeErrorConcurrentModification,
    // members, administrators, requests
    'LOGIN_SHARED' => l.memberErrorLoginShared,
    'LOGIN_REQUIRES_EMAIL' => l.memberErrorLoginRequiresEmail,
    'EMAIL_TAKEN' => l.adminErrorEmailTaken,
    'INVITATION_NOT_PENDING' => l.adminErrorInvitationNotPending,
    'IDENTITY_PROVIDER_UNAVAILABLE' => l.adminErrorIdentityProvider,
    'LAST_ADMIN' => l.adminLastAdminNote,
    'LOGIN_ALREADY_MEMBER' => l.adminErrorLoginAlreadyMember,
    'TENANT_WITHDRAWN' => l.adminsWithdrawn,
    'REQUEST_NOT_PENDING' => l.academyRequestErrorNotPending,
    'ACADEMY_NAME_TAKEN' => l.academyRequestErrorNameTaken,
    'SLUG_TAKEN' => l.academyRequestErrorSlugTaken,
    // exercise catalogue (ADR-0047)
    'EXERCISE_ARCHIVED' => l.exerciseArchivedError,
    'EXERCISE_IS_GLOBAL' => l.exerciseIsGlobal,
    _ => null,
  };

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
