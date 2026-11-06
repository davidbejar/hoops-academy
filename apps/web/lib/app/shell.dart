import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_providers.dart';
import '../core/navigation/destination_labels.dart';
import '../core/navigation/destinations.dart';
import '../core/pwa/update_providers.dart';
import '../core/session/session.dart';
import '../core/session/session_providers.dart';
import '../features/tenant/presentation/tenant_avatar.dart';
import '../l10n/gen/app_localizations.dart';
import 'theme.dart';

/// Scaffold around every role destination: tenant header, banners and the
/// role-aware navigation (bottom bar on phones, rail on wide screens).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    if (session is! Ready) return child;

    final destinations = destinationsFor(
      roles: session.roles,
      superAdmin: session.user.superAdmin,
    );
    final selected = destinations.indexWhere(
      (d) => location == d.path || location.startsWith('${d.path}/'),
    );
    final selectedIndex = selected < 0 ? 0 : selected;
    final wide = MediaQuery.sizeOf(context).width >= AppTokens.wideBreakpoint;
    final showNav = destinations.length > 1;
    final online = ref.watch(onlineProvider).value ?? true;
    final mock = ref.watch(appConfigProvider).mockApi;
    final membership = session.membership;
    final canSwitch = session.user.memberships.length > 1;

    void go(int i) => context.go(destinations[i].path);

    final body = Column(
      children: [
        if (!online) const _Banner(key: Key('offline-banner'), offline: true),
        if (ref.watch(updateAvailableProvider)) const _UpdateBanner(),
        if (mock)
          _Banner(key: const Key('mock-banner'), text: l.mockModeBanner),
        Expanded(child: child),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.spaceMd,
        title: InkWell(
          key: const Key('tenant-chip'),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          onTap: canSwitch ? () => context.go('/tenants') : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTokens.minTapTarget,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (membership != null) ...[
                  TenantAvatar(name: membership.tenantName),
                  const SizedBox(width: AppTokens.spaceSm),
                ],
                Flexible(
                  child: Text(
                    membership?.tenantName ?? l.appName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canSwitch) const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const Key('profile-button'),
            tooltip: l.profileTitle,
            icon: const Icon(Icons.account_circle_outlined),
            iconSize: 28,
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: wide && showNav
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: go,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label(l)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: !wide && showNav
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: go,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label(l),
                  ),
              ],
            )
          : null,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, this.offline = false, this.text});

  final bool offline;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Material(
      color: offline ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd,
          vertical: AppTokens.spaceSm,
        ),
        child: Row(
          children: [
            Icon(offline ? Icons.cloud_off : Icons.science_outlined, size: 18),
            const SizedBox(width: AppTokens.spaceSm),
            Expanded(
              child: Text(
                offline ? l.offlineBanner : text!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A new build is installed and waiting (service worker): offer the reload.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Material(
      key: const Key('update-banner'),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd,
          vertical: AppTokens.spaceXs,
        ),
        child: Row(
          children: [
            const Icon(Icons.system_update_alt, size: 18),
            const SizedBox(width: AppTokens.spaceSm),
            Expanded(
              child: Text(
                l.updateAvailable,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              key: const Key('update-reload'),
              onPressed: ref.read(updateAvailableProvider.notifier).reload,
              child: Text(l.updateReload),
            ),
          ],
        ),
      ),
    );
  }
}
