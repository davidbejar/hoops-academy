import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/locale_controller.dart';
import '../core/l10n/theme_mode_controller.dart';
import '../core/l10n/theme_mode_labels.dart';
import '../core/ui/kit.dart';
import '../features/me/application/me_providers.dart';
import '../l10n/gen/app_localizations.dart';

/// Opens the menu behind the avatar: the person, the profile, the language
/// and the theme. A sheet on phones, a panel at the top right from tablets
/// up (like the context switcher, which opens at the top left).
Future<void> showAvatarMenu(
  BuildContext context, {
  required String name,
  required String? email,
}) {
  Widget content(BuildContext inner) => AvatarMenu(
    name: name,
    email: email,
    onOpenProfile: () {
      Navigator.of(inner).pop();
      context.go('/profile');
    },
  );

  return WidthClass.of(context).isCompact
      ? showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (inner) => SafeArea(child: content(inner)),
        )
      : showDialog<void>(
          context: context,
          builder: (inner) => Dialog(
            key: const Key('avatar-menu-panel'),
            alignment: Alignment.topRight,
            insetPadding: const EdgeInsets.all(HoopsSpace.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: content(inner),
            ),
          ),
        );
}

/// The content of [showAvatarMenu]. Choosing a language or a theme applies
/// it at once and keeps the menu open, so both can be set in one visit.
class AvatarMenu extends ConsumerWidget {
  const AvatarMenu({
    super.key,
    required this.name,
    required this.email,
    required this.onOpenProfile,
  });

  final String name;
  final String? email;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final language = ref.watch(effectiveLocaleProvider).languageCode;
    final themeMode = ref.watch(themeModePreferenceProvider);

    Widget chosen(bool selected) => selected
        ? Icon(Icons.check_circle, color: c.brand)
        : const SizedBox.shrink();

    return SingleChildScrollView(
      key: const Key('avatar-menu'),
      padding: const EdgeInsets.fromLTRB(
        HoopsSpace.md,
        HoopsSpace.xs,
        HoopsSpace.md,
        HoopsSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HoopsSpace.gap,
        children: [
          ListRow(
            key: const Key('avatar-menu-profile'),
            leading: InitialsAvatar(name: name),
            title: name,
            subtitle: email ?? l.profileTitle,
            onTap: onOpenProfile,
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
                    trailing: chosen(code == language),
                    onTap: () => chooseLanguage(ref, code),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: l.themeTitle,
            child: Column(
              spacing: HoopsSpace.sm,
              children: [
                for (final mode in ThemeMode.values)
                  ListRow(
                    key: Key('theme-${mode.name}'),
                    leading: IconTile(
                      mode.icon,
                      tone: HoopsTone.neutral,
                      size: HoopsSize.minTapTarget - HoopsSpace.sm,
                    ),
                    title: mode.label(l),
                    trailing: chosen(mode == themeMode),
                    onTap: () => ref
                        .read(themeModePreferenceProvider.notifier)
                        .set(mode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _languageName(AppLocalizations l, String code) => switch (code) {
  'en' => l.languageName_en,
  'id' => l.languageName_id,
  _ => l.languageName_es,
};

/// Applies [code] in the browser at once and tells the server so the
/// person's e-mails follow; a failing call is not shown, the local choice
/// already applies.
Future<void> chooseLanguage(WidgetRef ref, String code) async {
  await ref.read(localePreferenceProvider.notifier).set(code);
  try {
    await ref.read(meRepositoryProvider).updateLocale(code);
  } on Object {
    // The server copy catches up with the next choice.
  }
}
