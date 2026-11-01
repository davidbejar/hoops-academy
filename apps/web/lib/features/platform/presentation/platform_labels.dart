import '../../../core/api/api.dart' as api;
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

