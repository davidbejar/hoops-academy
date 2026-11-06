import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/page_scaffold.dart' show ChipTone;
import '../../../l10n/gen/app_localizations.dart';

extension TenantStatusLabel on api.TenantStatus {
  String label(AppLocalizations l) => switch (this) {
    api.TenantStatus.ACTIVE => l.tenantStatusActive,
    api.TenantStatus.SUSPENDED => l.tenantStatusSuspended,
    _ => l.tenantStatusWithdrawn,
  };

  ChipTone get tone => switch (this) {
    api.TenantStatus.ACTIVE => ChipTone.good,
    api.TenantStatus.SUSPENDED => ChipTone.warn,
    _ => ChipTone.bad,
  };
}

extension InvitationStatusLabel on api.InvitationStatus {
  /// NONE (no invitation involved) has no label.
  String? label(AppLocalizations l) => switch (this) {
    api.InvitationStatus.PENDING => l.memberInvitationPending,
    api.InvitationStatus.ACCEPTED => l.adminInvitationAccepted,
    _ => null,
  };
}

/// Localised text for a failed administrator action, chosen by the server's error code (never its English detail).
String adminErrorText(Object error, AppLocalizations l) {
  final e = AppError.of(error);
  return switch (e.code) {
    'LAST_ADMIN' => l.adminLastAdminNote,
    'EMAIL_TAKEN' => l.adminErrorEmailTaken,
    'LOGIN_ALREADY_MEMBER' => l.adminErrorLoginAlreadyMember,
    'IDENTITY_PROVIDER_UNAVAILABLE' => l.adminErrorIdentityProvider,
    'INVITATION_NOT_PENDING' => l.adminErrorInvitationNotPending,
    'TENANT_WITHDRAWN' => l.adminsWithdrawn,
    _ => e.message(l),
  };
}
