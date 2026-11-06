import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/destination_labels.dart';
import '../../core/session/session.dart';
import '../../core/session/session_providers.dart';
import '../../core/tenancy/tenant_selection.dart';
import '../../features/me/domain/current_user.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/ui/kit.dart';

/// Lists the caller's academies (from `/me`) and stores the choice.
class TenantSwitcherScreen extends ConsumerWidget {
  const TenantSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final user = switch (session) {
      NeedsTenant(:final user) => user,
      Ready(:final user) => user,
      _ => null,
    };
    final activeId = ref.watch(activeTenantIdProvider);
    final memberships = user?.memberships ?? const <TenantMembership>[];

    final c = HoopsTokens.colorsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.switchAcademy),
        automaticallyImplyLeading: activeId != null,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('tenant-list'),
          padding: EdgeInsets.symmetric(
            vertical: WidthClass.of(context).sectionGap,
          ),
          children: [
            ContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: l.chooseAcademyTitle,
                    subtitle: l.chooseAcademySubtitle,
                  ),
                  const SizedBox(height: HoopsSpace.lg),
                  for (final m in memberships) ...[
                    ListRow(
                      key: Key('tenant-${m.tenantId}'),
                      leading: InitialsAvatar(name: m.tenantName),
                      title: m.tenantName,
                      subtitle: l.rolesInAcademy(
                        m.roles.map((r) => r.label(l)).join(', '),
                      ),
                      trailing: m.tenantId == activeId
                          ? Icon(Icons.check_circle, color: c.brand)
                          : Icon(Icons.chevron_right, color: c.inkMuted),
                      onTap: () async {
                        await ref
                            .read(selectedTenantIdProvider.notifier)
                            .select(m.tenantId);
                        if (context.mounted) context.go('/');
                      },
                    ),
                    const SizedBox(height: HoopsSpace.gap),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
