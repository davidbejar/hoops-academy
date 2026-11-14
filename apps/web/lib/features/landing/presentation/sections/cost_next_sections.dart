import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../landing_theme.dart';
import '../widgets/device_frame.dart';
import '../widgets/reveal.dart';
import 'story_sections.dart';

/// "Why it costs less" on a contrasting band, next to the platform's usage
/// screen.
class CostSection extends StatelessWidget {
  const CostSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.landingCostTitle,
            style: LandingType.title(w, p.bandText),
          ),
        ),
        const SizedBox(height: 24),
        Text(l.landingCostBody, style: LandingType.lead(w, p.bandMuted)),
      ],
    );
    final device = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const AccentGlow(color: LandingPalette.accent, size: 440),
        DeviceFrame(
          shot: LandingShot.platformUsage,
          width: w.isCompact ? 220 : 248,
          semanticLabel: l.landingFeatureAcademiesTitle,
          onDarkBackground: true,
        ),
      ],
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.band,
        border: Border.symmetric(horizontal: BorderSide(color: p.bandBorder)),
      ),
      padding: EdgeInsets.symmetric(vertical: w.sectionGap * 0.85),
      child: LandingFrame(
        child: Reveal(
          child: w.isWide
              ? Row(
                  children: [
                    Expanded(flex: 4, child: Center(child: device)),
                    const SizedBox(width: 72),
                    Expanded(flex: 7, child: text),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    text,
                    const SizedBox(height: 48),
                    Center(child: device),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The roadmap teaser: four items from docs/roadmap.md.
class NextSection extends StatelessWidget {
  const NextSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final items = [
      (
        Icons.notifications_none_rounded,
        l.landingNextNotificationsTitle,
        l.landingNextNotificationsLine,
      ),
      (
        Icons.how_to_reg_outlined,
        l.landingNextSignupTitle,
        l.landingNextSignupLine,
      ),
      (
        Icons.extension_outlined,
        l.landingNextIntegrationsTitle,
        l.landingNextIntegrationsLine,
      ),
      (
        Icons.insert_chart_outlined_rounded,
        l.landingNextReportsTitle,
        l.landingNextReportsLine,
      ),
    ];
    final columns = switch (w) {
      LandingWidth.wide => 4,
      LandingWidth.medium => 2,
      LandingWidth.compact => 1,
    };
    return LandingFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            child: Semantics(
              header: true,
              child: Text(
                l.landingNextTitle,
                style: LandingType.title(w, p.text),
              ),
            ),
          ),
          SizedBox(height: w.isCompact ? 32 : 48),
          LandingGrid(
            columns: columns,
            spacing: w.isCompact ? 14 : 20,
            children: [
              for (final (i, (icon, title, line)) in items.indexed)
                Reveal(
                  delay: Duration(milliseconds: 70 * (i % columns)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: p.muted, size: 26),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          style: LandingType.cardTitle(p.text)
                              .copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(line, style: LandingType.body(p.muted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
