import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_providers.dart';
import '../../../core/tenancy/tenant_selection.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../me/application/me_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _languageName(AppLocalizations l, String code) => switch (code) {
    'en' => l.languageName_en,
    'id' => l.languageName_id,
    _ => l.languageName_es,
  };

  Future<void> _pickLanguage(WidgetRef ref, String code) async {
    await ref.read(localePreferenceProvider.notifier).set(code);
    try {
      await ref.read(meRepositoryProvider).updateLocale(code);
    } on Object {
      // The local choice already applies; the server copy catches up later.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final user = switch (session) {
      NeedsTenant(:final user) => user,
      Ready(:final user) => user,
      _ => null,
    };
    final current = ref.watch(effectiveLocaleProvider).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              children: [
                if (user != null)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user.displayName),
                    subtitle: user.email == null ? null : Text(user.email!),
                  ),
                if (user != null && user.memberships.length > 1)
                  ListTile(
                    key: const Key('switch-academy'),
                    leading: const Icon(Icons.swap_horiz),
                    title: Text(l.switchAcademy),
                    onTap: () => context.go('/tenants'),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMd,
                    vertical: AppTokens.spaceSm,
                  ),
                  child: Text(l.language, style: theme.textTheme.titleSmall),
                ),
                for (final code in supportedLanguageCodes)
                  ListTile(
                    key: Key('lang-$code'),
                    title: Text(_languageName(l, code)),
                    trailing: code == current ? const Icon(Icons.check) : null,
                    selected: code == current,
                    onTap: () => _pickLanguage(ref, code),
                  ),
                const Divider(),
                const SizedBox(height: AppTokens.spaceSm),
                OutlinedButton.icon(
                  key: const Key('sign-out-button'),
                  icon: const Icon(Icons.logout),
                  label: Text(l.signOut),
                  onPressed: () async {
                    await ref.read(selectedTenantIdProvider.notifier).clear();
                    await ref.read(authServiceProvider).logout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
