import '../../../core/api/api.dart' as api;
import '../../../core/ui/kit.dart' show HoopsTone;
import '../../../l10n/gen/app_localizations.dart';

extension TenantStatusLabel on api.TenantStatus {
  String label(AppLocalizations l) => switch (this) {
    api.TenantStatus.ACTIVE => l.tenantStatusActive,
    api.TenantStatus.SUSPENDED => l.tenantStatusSuspended,
    _ => l.tenantStatusWithdrawn,
  };

  HoopsTone get tone => switch (this) {
    api.TenantStatus.ACTIVE => HoopsTone.success,
    api.TenantStatus.SUSPENDED => HoopsTone.warning,
    _ => HoopsTone.danger,
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
