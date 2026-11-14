import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_providers.dart';
import '../core/navigation/context_switcher.dart';
import '../core/navigation/destination_labels.dart';
import '../core/navigation/destinations.dart';
import '../core/pwa/update_providers.dart';
import '../core/session/session.dart';
import '../core/session/session_providers.dart';
import '../core/design/tokens.dart';
import '../core/ui/list_row.dart';
import '../core/ui/notice_banner.dart';
import '../features/platform/application/academy_request_providers.dart';
import '../l10n/gen/app_localizations.dart';
import 'avatar_menu.dart';

/// The destination of [location]: the longest matching path, because the
/// application admin's hub path (`/app-admin`) is a prefix of its areas.
int selectedDestination(List<AppDestination> destinations, String location) {
  var best = -1;
  for (final (i, d) in destinations.indexed) {
    final matches = location == d.path || location.startsWith('${d.path}/');
    if (matches &&
        (best < 0 || d.path.length > destinations[best].path.length)) {
      best = i;
    }
  }
  return best < 0 ? 0 : best;
}

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
      applicationAdmin: session.applicationAdmin,
    );
    final selectedIndex = selectedDestination(destinations, location);
    final pending = session.applicationAdmin
        ? ref.watch(pendingRequestsCountProvider) ?? 0
        : 0;
    Widget icon(AppDestination d, {bool selected = false}) {
      final icon = Icon(selected ? d.selectedIcon : d.icon);
      return d == AppDestination.appRequests && pending > 0
          ? Badge.count(
              key: const Key('nav-requests-badge'),
              count: pending,
              child: icon,
            )
          : icon;
    }

    final width = WidthClass.of(context);
    final showNav = destinations.length > 1;
    final online = ref.watch(onlineProvider).value ?? true;
    final mock = ref.watch(appConfigProvider).mockApi;
    final c = HoopsTokens.colorsOf(context);

    void go(int i) => context.go(destinations[i].path);

    final body = Column(
      children: [
        if (!online)
          NoticeBanner(
            key: const Key('offline-banner'),
            tone: HoopsTone.warning,
            icon: Icons.cloud_off,
            message: l.offlineBanner,
          ),
        if (ref.watch(updateAvailableProvider)) const _UpdateBanner(),
        if (mock)
          NoticeBanner(
            key: const Key('mock-banner'),
            icon: Icons.science_outlined,
            message: l.mockModeBanner,
          ),
        Expanded(child: child),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: width.gutter - HoopsSpace.sm,
        title: ContextChip(session: session),
        actions: [
          _ProfileButton(
            name: session.user.displayName,
            email: session.user.email,
          ),
          SizedBox(width: width.gutter - HoopsSpace.sm),
        ],
      ),
      body: !width.isCompact && showNav
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  extended: width == WidthClass.expanded,
                  labelType: width == WidthClass.expanded
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: go,
                  leading: Column(
                    children: [
                      _RailBrand(extended: width == WidthClass.expanded),
                      RailContextButton(extended: width == WidthClass.expanded),
                    ],
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: icon(d),
                        selectedIcon: icon(d, selected: true),
                        label: Text(d.label(l)),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: c.border),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: width.isCompact && showNav
          ? DecoratedBox(
              key: const Key('nav-bar-frame'),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: go,
                destinations: [
                  for (final d in destinations)
                    NavigationDestination(
                      icon: icon(d),
                      selectedIcon: icon(d, selected: true),
                      label: d.label(l),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}

/// The signed-in person's initials; opens the menu with the profile, the
/// language and the theme.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.name, required this.email});

  final String name;
  final String? email;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('profile-button'),
    tooltip: AppLocalizations.of(context).profileTitle,
    padding: EdgeInsets.zero,
    icon: InitialsAvatar(name: name, size: 36, tone: HoopsTone.neutral),
    onPressed: () => showAvatarMenu(context, name: name, email: email),
  );
}

/// The landing's basketball mark at the top of the rail.
class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    const mark = Icon(
      Icons.sports_basketball,
      color: HoopsColors.brandOrange,
      size: 28,
    );
    return Padding(
      key: const Key('rail-brand'),
      padding: const EdgeInsets.only(top: HoopsSpace.sm, bottom: HoopsSpace.lg),
      child: extended
          ? SizedBox(
              width: 200,
              child: Row(
                children: [
                  const SizedBox(width: HoopsSpace.md),
                  mark,
                  const SizedBox(width: HoopsSpace.sm + 2),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context).appName,
                      overflow: TextOverflow.ellipsis,
                      style: HoopsType.brand(
                        Theme.of(context).textTheme,
                        c,
                      ).copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
            )
          : mark,
    );
  }
}

/// A new build is installed and waiting (service worker): offer the reload.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return NoticeBanner(
      key: const Key('update-banner'),
      tone: HoopsTone.info,
      icon: Icons.system_update_alt,
      message: l.updateAvailable,
      action: TextButton(
        key: const Key('update-reload'),
        onPressed: ref.read(updateAvailableProvider.notifier).reload,
        child: Text(l.updateReload),
      ),
    );
  }
}
