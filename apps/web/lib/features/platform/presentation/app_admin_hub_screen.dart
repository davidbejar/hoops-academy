import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/academy_request_providers.dart';
import '../application/platform_providers.dart';

/// The application admin hub (WP99), like the academy admin hub: one entry
/// per area of what a super admin can do. Loaded through a deferred import
/// (see `app/feature_modules.dart`).
class AppAdminHubScreen extends ConsumerWidget {
  const AppAdminHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pending = ref.watch(pendingRequestsCountProvider);
    final entries = [
      (
        Icons.apartment_outlined,
        l.appAdminAcademies,
        '/app-admin/academies',
        'app-admin-academies',
        null,
      ),
      (
        Icons.people_outline,
        l.appAdminUsers,
        '/app-admin/users',
        'app-admin-users',
        null,
      ),
      (
        Icons.mark_email_unread_outlined,
        l.appAdminPending,
        '/app-admin/requests',
        'app-admin-requests',
        pending,
      ),
      (
        Icons.history,
        l.appAdminAudit,
        '/app-admin/activity',
        'app-admin-activity',
        null,
      ),
      (
        Icons.receipt_long_outlined,
        l.appAdminBilling,
        '/app-admin/billing',
        'app-admin-billing',
        null,
      ),
    ];
    return Guarded(
      allowed: ref.watch(isSuperAdminProvider),
      child: PageBody(
        key: const Key('app-admin-hub'),
        header: PageHeader(title: l.appAdminTitle),
        children: [
          Column(
            spacing: HoopsSpace.gap,
            children: [
              for (final (icon, label, path, key, badge) in entries)
                ListRow(
                  key: Key(key),
                  leading: IconTile(icon),
                  title: label,
                  subtitle: key == 'app-admin-billing' ? l.appAdminSoon : null,
                  trailing: badge == null || badge == 0
                      ? null
                      : _CountBadge(key: Key('$key-badge'), count: badge),
                  onTap: () => context.go(path),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: HoopsSpace.xs,
    children: [
      StatusChip('$count', tone: HoopsTone.accent),
      Icon(Icons.chevron_right, color: HoopsTokens.colorsOf(context).inkMuted),
    ],
  );
}
