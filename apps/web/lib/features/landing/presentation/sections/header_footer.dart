import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../application/external_link.dart';
import '../landing_theme.dart';

/// The repository the AGPL line points to.
final landingSourceUrl = Uri.parse(
  'https://github.com/davidbejar/hoops-academy',
);

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final p = LandingPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.sports_basketball,
          color: LandingPalette.accent,
          size: 28,
        ),
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
