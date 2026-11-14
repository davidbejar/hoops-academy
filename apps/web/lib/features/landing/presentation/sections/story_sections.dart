import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../landing_theme.dart';
import '../widgets/device_frame.dart';
import '../widgets/reveal.dart';

/// "Why basketball-only": the positioning statement next to the health
/// screen.
class WhySection extends StatelessWidget {
  const WhySection({super.key});

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
          child: Text(l.landingWhyTitle, style: LandingType.title(w, p.text)),
        ),
        const SizedBox(height: 24),
        Text(l.landingWhyBody, style: LandingType.lead(w, p.muted)),
      ],
    );
    final device = DeviceFrame(
      shot: LandingShot.playerHealth,
      width: w.isCompact ? 220 : 248,
      semanticLabel: l.landingFeatureHealthTitle,
    );
    return LandingFrame(
      child: Reveal(
        child: w.isWide
            ? Row(
                children: [
                  Expanded(flex: 7, child: text),
                  const SizedBox(width: 72),
                  Expanded(
                    flex: 4,
                    child: Center(child: _Spotlight(child: device)),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  text,
                  const SizedBox(height: 48),
                  Center(child: _Spotlight(child: device)),
                ],
              ),
      ),
    );
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      const AccentGlow(color: LandingPalette.accent, size: 420),
      child,
    ],
  );
}

class _Feature {
  const _Feature(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

/// The six feature areas: 3x2 on desktop, 2 columns on tablets, one on phones.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = LandingWidth.of(context);
    final features = [
      _Feature(
        Icons.fact_check_outlined,
        l.landingFeatureRosterTitle,
        l.landingFeatureRosterBody,
      ),
      _Feature(
        Icons.scoreboard_outlined,
        l.landingFeatureStatsTitle,
        l.landingFeatureStatsBody,
      ),
      _Feature(
        Icons.event_available_outlined,
        l.landingFeatureTrainingTitle,
        l.landingFeatureTrainingBody,
      ),
      _Feature(
        Icons.monitor_heart_outlined,
        l.landingFeatureHealthTitle,
        l.landingFeatureHealthBody,
      ),
      _Feature(
        Icons.family_restroom_outlined,
        l.landingFeatureFamiliesTitle,
        l.landingFeatureFamiliesBody,
      ),
      _Feature(
        Icons.swap_horiz_rounded,
        l.landingFeatureAcademiesTitle,
        l.landingFeatureAcademiesBody,
      ),
    ];
    final columns = switch (w) {
      LandingWidth.wide => 3,
      LandingWidth.medium => 2,
      LandingWidth.compact => 1,
    };
    return LandingFrame(
      child: LandingGrid(
        columns: columns,
        spacing: w.isCompact ? 16 : 24,
        children: [
          for (final (i, f) in features.indexed)
            Reveal(
              delay: Duration(milliseconds: 70 * (i % columns)),
              child: _FeatureCard(feature: f),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final p = LandingPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: LandingPalette.accent, size: 26),
          ),
          const SizedBox(height: 22),
          Text(feature.title, style: LandingType.cardTitle(p.text)),
          const SizedBox(height: 10),
          Text(feature.body, style: LandingType.body(p.muted)),
        ],
      ),
    );
  }
}

/// The four roles, each with its one line: a row on desktop.
class RolesSection extends StatelessWidget {
  const RolesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = LandingPalette.of(context);
    final w = LandingWidth.of(context);
    final roles = [
      (l.landingRoleAdmin, l.landingRoleAdminLine),
      (l.landingRoleCoach, l.landingRoleCoachLine),
      (l.landingRoleParent, l.landingRoleParentLine),
      (l.landingRolePlayer, l.landingRolePlayerLine),
    ];
    final columns = switch (w) {
      LandingWidth.wide => 4,
      LandingWidth.medium => 2,
      LandingWidth.compact => 1,
    };
    return LandingFrame(
      child: Container(
        padding: EdgeInsets.only(top: w.isCompact ? 40 : 56),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: LandingGrid(
          columns: columns,
          spacing: w.isCompact ? 32 : 40,
          children: [
            for (final (i, (name, line)) in roles.indexed)
              Reveal(
                delay: Duration(milliseconds: 70 * (i % columns)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      color: LandingPalette.accent,
                    ),
                    const SizedBox(height: 18),
                    Text(name, style: LandingType.eyebrow(p.accentText)),
                    const SizedBox(height: 10),
                    Text(
                      line,
                      style: TextStyle(
                        fontSize: w.isCompact ? 18 : 19,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rows of [columns] equally wide cells; cells in a row share their height.
class LandingGrid extends StatelessWidget {
  const LandingGrid({
    super.key,
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = children.skip(start).take(columns).toList();
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: i < cells.length ? cells[i] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
