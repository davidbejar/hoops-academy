import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/l10n/theme_mode_controller.dart';
import '../../../../core/l10n/theme_mode_labels.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../application/external_link.dart';
import '../landing_theme.dart';

/// The repository the AGPL line points to.
final landingSourceUrl = Uri.parse(
  'https://github.com/davidbejar/hoops-academy',
);

class _Brand extends StatelessWidget {
  const _Brand();

  /// Below this width the name would be cut to a few letters: the mark
  /// stays alone (the header also holds the language and theme switches).
  static const _minWidthForName = 110.0;

  @override
  Widget build(BuildContext context) {
    final p = LandingPalette.of(context);
    const mark = Icon(
      Icons.sports_basketball,
      color: LandingPalette.accent,
      size: 28,
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < _minWidthForName
          ? mark
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Top bar: brand, sign in and (from tablets up) the invitation request.
class LandingHeader extends ConsumerWidget {
  const LandingHeader({
    super.key,
    required this.scrolled,
    required this.onRequestInvitation,
    required this.onSignIn,
  });

  /// Draws the separator once the page has moved under the bar.
  final bool scrolled;
  final VoidCallback onRequestInvitation;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? p.border : p.border.withValues(alpha: 0),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LandingFrame(
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                const Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _Brand(),
                  ),
                ),
                const _HeaderLanguageMenu(),
                const _HeaderThemeMenu(),
                TextButton(
                  key: const Key('landing-header-sign-in'),
                  style: landingLinkButton(context, p.text),
                  onPressed: onSignIn,
                  child: Text(l.landingSignIn),
                ),
                if (!w.isCompact) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('landing-header-request'),
                    style: landingPrimaryButton(context, large: false),
                    onPressed: onRequestInvitation,
                    child: Text(l.landingRequestInvitation),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Language switch for the header: the current code, a menu of the three.
class _HeaderLanguageMenu extends ConsumerWidget {
  const _HeaderLanguageMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final current = Localizations.localeOf(context).languageCode;
    final names = {
      'es': l.languageName_es,
      'en': l.languageName_en,
      'id': l.languageName_id,
    };
    return PopupMenuButton<String>(
      key: const Key('landing-header-lang'),
      tooltip: l.language,
      position: PopupMenuPosition.under,
      onSelected: (code) =>
          ref.read(localePreferenceProvider.notifier).set(code),
      itemBuilder: (_) => [
        for (final code in supportedLanguageCodes)
          PopupMenuItem(
            key: Key('landing-header-lang-$code'),
            value: code,
            enabled: code != current,
            child: Text(names[code]!),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, size: 18, color: p.muted),
            const SizedBox(width: 4),
            Text(
              current.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Theme switch for the header: an icon of the current choice, a menu of
/// light, dark and system.
class _HeaderThemeMenu extends ConsumerWidget {
  const _HeaderThemeMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final current = ref.watch(themeModePreferenceProvider);
    return PopupMenuButton<ThemeMode>(
      key: const Key('landing-header-theme'),
      tooltip: l.themeTitle,
      position: PopupMenuPosition.under,
      onSelected: ref.read(themeModePreferenceProvider.notifier).set,
      itemBuilder: (_) => [
        for (final mode in ThemeMode.values)
          PopupMenuItem(
            key: Key('landing-header-theme-${mode.name}'),
            value: mode,
            enabled: mode != current,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon, size: 18),
                const SizedBox(width: 12),
                Text(mode.label(l)),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 40),
        child: Icon(current.icon, size: 20, color: p.muted),
      ),
    );
  }
}

/// AGPL line with the source link, language switch, sign in.
class LandingFooter extends ConsumerWidget {
  const LandingFooter({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final current = Localizations.localeOf(context).languageCode;
    final license = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Brand(),
        const SizedBox(height: 16),
        Text(l.landingFooterLicense, style: LandingType.small(p.muted)),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: TextButton(
            key: const Key('landing-source-link'),
            style: landingLinkButton(context, p.accentText),
            onPressed: () =>
                ref.read(externalLinkOpenerProvider).open(landingSourceUrl),
            child: Text(l.landingFooterSource),
          ),
        ),
      ],
    );
    final names = {
      'es': l.languageName_es,
      'en': l.languageName_en,
      'id': l.languageName_id,
    };
    final languages = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final code in supportedLanguageCodes)
          TextButton(
            key: Key('landing-lang-$code'),
            style: landingLinkButton(
              context,
              code == current ? p.accentText : p.muted,
            ),
            onPressed: code == current
                ? null
                : () => ref.read(localePreferenceProvider.notifier).set(code),
            child: Text(names[code]!),
          ),
        TextButton(
          key: const Key('landing-footer-sign-in'),
          style: landingLinkButton(context, p.text),
          onPressed: onSignIn,
          child: Text(l.landingSignIn),
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: LandingFrame(
        child: w.isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  license,
                  const SizedBox(height: 16),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: languages,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: license),
                  const SizedBox(width: 32),
                  languages,
                ],
              ),
      ),
    );
  }
}
