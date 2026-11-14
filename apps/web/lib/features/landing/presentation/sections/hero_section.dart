import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../landing_theme.dart';
import '../widgets/court_lines.dart';
import '../widgets/device_frame.dart';
import '../widgets/reveal.dart';

/// Eyebrow, headline, the two calls to action and the device mock-ups.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onRequestInvitation,
    required this.onSignIn,
  });

  final VoidCallback onRequestInvitation;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final w = LandingWidth.of(context);
    final sideBySide = MediaQuery.sizeOf(context).width >= 960;
    final copy = _HeroCopy(
      onRequestInvitation: onRequestInvitation,
      onSignIn: onSignIn,
    );
    return LandingFrame(
      child: Padding(
        padding: EdgeInsets.only(
          top: w.isCompact ? 32 : 56,
          bottom: w.isCompact ? 24 : 40,
        ),
        child: sideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 48),
                  const Expanded(
                    flex: 9,
                    child: Reveal(
                      delay: Duration(milliseconds: 300),
                      child: _HeroDevices(phoneWidth: 272),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  SizedBox(height: w.isCompact ? 48 : 64),
                  Reveal(
                    delay: const Duration(milliseconds: 300),
                    child: _HeroDevices(phoneWidth: w.isCompact ? 236 : 272),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onRequestInvitation, required this.onSignIn});

  final VoidCallback onRequestInvitation;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final primary = FilledButton(
      key: const Key('landing-request-invitation'),
      style: landingPrimaryButton(context),
      onPressed: onRequestInvitation,
      child: Text(l.landingRequestInvitation, textAlign: TextAlign.center),
    );
    final secondary = OutlinedButton(
      key: const Key('landing-sign-in'),
      style: landingSecondaryButton(context),
      onPressed: onSignIn,
      child: Text(l.landingSignIn, textAlign: TextAlign.center),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: _Eyebrow(text: l.landingEyebrow)),
        const SizedBox(height: 24),
        Reveal(
          delay: const Duration(milliseconds: 80),
          child: Semantics(
            header: true,
            child: Text(
              l.landingHeadline,
              style: LandingType.headline(w, p.text),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: const Duration(milliseconds: 160),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              l.landingSubheadline,
              style: LandingType.lead(w, p.muted),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Reveal(
          delay: const Duration(milliseconds: 240),
          child: w.isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [primary, const SizedBox(height: 12), secondary],
                )
              : Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [primary, secondary],
                ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 320),
          child: Text(l.landingProofLine, style: LandingType.small(p.muted)),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LandingPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_basketball,
            size: 18,
            color: LandingPalette.accent,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: LandingType.small(p.accentText)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// The live match in front, the training week behind it, on court markings.
class _HeroDevices extends StatelessWidget {
  const _HeroDevices({required this.phoneWidth});

  final double phoneWidth;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final phoneHeight = DeviceFrame.heightFor(phoneWidth);
    final compact = LandingWidth.of(context).isCompact;
    final offset = phoneWidth * (compact ? 0.26 : 0.36);
    return SizedBox(
      height: phoneHeight + 24,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CourtLines(color: p.text.withValues(alpha: 0.07)),
          ),
          AccentGlow(color: LandingPalette.accent, size: phoneWidth * 2.1),
          Transform.translate(
            offset: Offset(-offset, -18),
            child: Transform.scale(
              scale: 0.86,
              child: DeviceFrame(
                shot: LandingShot.trainingWeek,
                width: phoneWidth,
                semanticLabel: l.landingFeatureTrainingTitle,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(offset * 0.55, 12),
            child: DeviceFrame(
              shot: LandingShot.liveMatch,
              width: phoneWidth,
              semanticLabel: l.landingFeatureStatsTitle,
            ),
          ),
        ],
      ),
    );
  }
}
