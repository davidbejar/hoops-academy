import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_providers.dart';
import '../core/auth/auth_service.dart';
import '../core/navigation/destinations.dart';
import '../core/session/session.dart';
import '../core/session/session_providers.dart';
import '../core/tenancy/tenant_selection.dart';
import '../core/ui/app_error_view.dart';
import '../core/ui/deferred_screen.dart';
import '../features/landing/presentation/landing_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/tenant_switcher_screen.dart';
import 'feature_modules.dart';
import 'shell.dart';

/// Router whose guard is [redirectFor]; it re-evaluates whenever the session
/// (auth status, profile, selected tenant) changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute module(AppDestination destination, FeatureModule feature) => GoRoute(
    path: destination.path,
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: DeferredScreen(
        load: feature.load,
        builder: (_) => feature.build(),
      ),
    ),
    routes: [
      for (final sub in feature.subPages)
        GoRoute(
          path: sub.path,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: DeferredScreen(
              load: sub.load,
              builder: (_) => sub.build(state.pathParameters),
            ),
          ),
        ),
    ],
  );

  String? lastPath;

  // No initialLocation: a cold start keeps the browser's path, so an
  // anonymous visit to `/` can become the landing (WP70).
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      // A refresh (the session changed) asks again for the same location;
      // only a navigation to a new one is a link being followed.
      if (path != lastPath) _enterApplicationAdminForLink(ref, path);
      lastPath = path;
      return redirectFor(ref.read(sessionProvider), path);
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _LandingGate()),
      GoRoute(path: '/welcome', builder: (_, _) => const _LandingGate()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/no-access', builder: (_, _) => const NoAccessScreen()),
      GoRoute(
        path: '/tenants',
        builder: (_, _) => const TenantSwitcherScreen(),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          for (final entry in featureModules.entries)
            module(entry.key, entry.value),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// A link to the application admin (`/app-admin/...`, or an old `/platform/...`
/// one) followed by a super admin working in an academy is an explicit choice
/// of that context: remember it before the guard decides, so the link opens
/// instead of bouncing to the menu of the academy that was active (WP99).
void _enterApplicationAdminForLink(Ref ref, String location) {
  if (!isApplicationAdminPath(location) &&
      legacyPlatformPath(location) == null) {
    return;
  }
  final session = ref.read(sessionProvider);
  if (session is Ready &&
      session.user.superAdmin &&
      !session.applicationAdmin) {
    ref.read(selectedTenantIdProvider.notifier).select(platformContextId);
  }
}

/// The landing for anonymous visitors; the splash while the auth status is
/// still unknown, so a signed-in user never sees the landing flash by.
class _LandingGate extends ConsumerWidget {
  const _LandingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(authStatusProvider) == AuthStatus.unknown
      ? const Scaffold(body: LoadingView())
      : const LandingScreen();
}
