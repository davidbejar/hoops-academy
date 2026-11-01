import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_error.dart';
import '../../core/tenancy/tenant_selection.dart';
import '../../core/ui/app_error_view.dart';
import '../../features/me/application/me_providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme.dart';

/// Shown while auth/profile initialise, and when loading `/me` failed.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: me.hasError && !me.isLoading
            ? Column(
                children: [
                  Expanded(
                    child: AppErrorView(
                      error: AppError.of(me.error!),
                      onRetry: () => ref.invalidate(currentUserProvider),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    child: TextButton(
                      key: const Key('splash-sign-out'),
                      onPressed: () => ref.read(authServiceProvider).logout(),
                      child: Text(l.signOut),
                    ),
                  ),
                ],
              )
            : const LoadingView(),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = AppLocalizations.of(context).errorUnknown;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).login();
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mock = ref.watch(appConfigProvider).mockApi;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.sports_basketball,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppTokens.spaceMd),
                  Text(
                    l.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  Text(
                    l.signInSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  FilledButton(
                    key: const Key('login-button'),
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.signIn),
                  ),
                  if (mock) ...[
                    const SizedBox(height: AppTokens.spaceMd),
                    Text(
                      l.mockModeBanner,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          key: const Key('no-access'),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: AppTokens.spaceMd),
                Text(l.noAccessTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppTokens.spaceSm),
                Text(l.noAccessBody, textAlign: TextAlign.center),
                const SizedBox(height: AppTokens.spaceLg),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(selectedTenantIdProvider.notifier).clear();
                    await ref.read(authServiceProvider).logout();
                  },
                  child: Text(l.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
