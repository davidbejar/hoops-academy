import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/signed_in_email.dart';
import '../sign_out.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_error.dart';
import '../../core/design/tokens.dart';
import '../../core/ui/app_error_view.dart';
import '../../core/ui/empty_state.dart';
import '../../features/me/application/me_providers.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shown while auth/profile initialise, and when loading `/me` failed.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: me.hasError && !me.isLoading
            ? (_isNotMember(me.error!)
                  ? _NotAMember(email: ref.watch(signedInEmailProvider).value)
                  : Column(
                      children: [
                        Expanded(
                          child: AppErrorView(
                            error: AppError.of(me.error!),
                            onRetry: () => ref.invalidate(currentUserProvider),
                          ),
                        ),
                        const _SplashSignOut(),
                      ],
                    ))
            : const LoadingView(),
      ),
    );
  }
}

bool _isNotMember(Object error) =>
    AppError.of(error).kind == AppErrorKind.notFound;

class _SplashSignOut extends ConsumerWidget {
  const _SplashSignOut();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(HoopsSpace.md),
    child: TextButton(
      key: const Key('splash-sign-out'),
      onPressed: () => confirmAndSignOut(context, ref),
      child: Text(AppLocalizations.of(context).signOut),
    ),
  );
}

/// `/me` answered 404: the login exists but no academy knows this e-mail.
class _NotAMember extends StatelessWidget {
  const _NotAMember({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      key: const Key('not-a-member'),
      icon: Icons.group_off_outlined,
      title: l.notMemberTitle,
      message: email == null ? l.notMemberBodyNoEmail : l.notMemberBody(email!),
      action: const _SplashSignOut(),
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
    final c = HoopsTokens.colorsOf(context);
    final mock = ref.watch(appConfigProvider).mockApi;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HoopsSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            borderRadius: BorderRadius.circular(HoopsRadius.lg),
                          ),
                          child: const SizedBox.square(
                            dimension: 72,
                            child: Icon(
                              Icons.sports_basketball,
                              size: 40,
                              color: HoopsColors.brandOrange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: HoopsSpace.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          l.appName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: HoopsSpace.sm),
                      Text(
                        l.signInSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: c.inkMuted,
                        ),
                      ),
                      const SizedBox(height: HoopsSpace.xl),
                      FilledButton(
                        key: const Key('login-button'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: _busy ? null : _signIn,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l.signIn),
                      ),
                      if (mock) ...[
                        const SizedBox(height: HoopsSpace.md),
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
            // Back to the public landing page (WP70).
            Positioned(
              top: HoopsSpace.sm,
              left: HoopsSpace.sm,
              child: TextButton.icon(
                key: const Key('login-back'),
                style: TextButton.styleFrom(foregroundColor: c.ink),
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
                label: Text(l.landingBack),
              ),
            ),
          ],
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
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          key: const Key('no-access'),
          icon: Icons.lock_outline,
          title: l.noAccessTitle,
          message: l.noAccessBody,
          action: OutlinedButton(
            onPressed: () => confirmAndSignOut(context, ref),
            child: Text(l.signOut),
          ),
        ),
      ),
    );
  }
}
