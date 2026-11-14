import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/sign_out.dart';
import '../../../core/config/app_config.dart';
import '../../../core/http/mock_api_adapter.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/navigation/external_link.dart';
import '../../../core/mock/mock_reload.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_providers.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../me/application/me_providers.dart';
import '../../me/domain/current_user.dart' show TenantRole;
import 'profile_name_section.dart';

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

  /// Keycloak's account console of the realm: `<issuer>/account` (password, two-step verification, sessions).
  Uri _accountConsole(Uri issuer) => issuer.replace(
    path: '${issuer.path.replaceFirst(RegExp(r'/+$'), '')}/account',
  );

  /// Demo mode only: forgets what was changed (browser storage and the running mock) and starts the page afresh.
  Future<void> _resetDemo(WidgetRef ref) async {
    await ref.read(mockApiAdapterProvider).reset();
    reloadPage();
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
    // The member record (name, e-mail, phone) is editable by an ADMIN only.
    final ownMemberId = switch (session) {
      Ready(:final roles, :final membership)
          when roles.contains(TenantRole.admin) =>
        membership?.personId,
      _ => null,
    };
    final c = HoopsTokens.colorsOf(context);
    // The own name belongs to the person in the active academy; the
    // application admin has none.
    final ownAcademyId = switch (session) {
      Ready(:final membership) => membership?.tenantId,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SafeArea(
        child: PageBody(
          children: [
            if (user != null)
              ListRow(
                leading: InitialsAvatar(name: user.displayName),
                title: user.displayName,
                subtitle: user.email,
                trailing: const SizedBox.shrink(),
              ),
            if (user != null)
              Column(
                spacing: HoopsSpace.gap,
                children: [
                  if (ownMemberId != null)
                    ListRow(
                      key: const Key('profile-own-data'),
                      leading: const IconTile(Icons.badge_outlined),
                      title: l.profileOwnData,
                      onTap: () => context.go('/admin/members/$ownMemberId'),
                    ),
                  if (!ref.watch(appConfigProvider).mockApi)
                    ListRow(
                      key: const Key('open-account-console'),
                      leading: const IconTile(Icons.manage_accounts_outlined),
                      title: l.profileAccount,
                      subtitle: l.profileAccountHint,
                      trailing: Icon(Icons.open_in_new, color: c.inkMuted),
                      onTap: () => ref.read(externalLinkOpenerProvider)(
                        _accountConsole(ref.read(appConfigProvider).issuer),
                      ),
                    ),
                  if (contextsOf(user).length > 1)
                    ListRow(
                      key: const Key('switch-academy'),
                      leading: const IconTile(Icons.swap_horiz),
                      title: l.switchContext,
                      onTap: () => context.go('/tenants'),
                    ),
                  if (ref.watch(appConfigProvider).mockApi)
                    ListRow(
                      key: const Key('reset-demo-data'),
                      leading: const IconTile(
                        Icons.restart_alt,
                        tone: HoopsTone.neutral,
                      ),
                      title: l.profileResetDemo,
                      onTap: () => _resetDemo(ref),
                    ),
                ],
              ),
            if (user != null && ownAcademyId != null)
              ProfileNameSection(
                tenantId: ownAcademyId,
                displayName: user.displayName,
              ),
            SectionCard(
              title: l.language,
              child: Column(
                spacing: HoopsSpace.sm,
                children: [
                  for (final code in supportedLanguageCodes)
                    ListRow(
                      key: Key('lang-$code'),
                      title: _languageName(l, code),
                      trailing: code == current
                          ? Icon(Icons.check_circle, color: c.brand)
                          : const SizedBox.shrink(),
                      onTap: () => _pickLanguage(ref, code),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('sign-out-button'),
                icon: const Icon(Icons.logout),
                label: Text(l.signOut),
                onPressed: () => confirmAndSignOut(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
