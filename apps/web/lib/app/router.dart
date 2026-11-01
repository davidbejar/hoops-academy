import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/destinations.dart';
import '../core/session/session.dart';
import '../core/session/session_providers.dart';
import '../core/ui/deferred_screen.dart';
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
      child: DeferredScreen(load: feature.load, builder: (_) => feature.build()),
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

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectFor(ref.read(sessionProvider), state.uri.path),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/no-access', builder: (_, _) => const NoAccessScreen()),
      GoRoute(path: '/tenants', builder: (_, _) => const TenantSwitcherScreen()),
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
