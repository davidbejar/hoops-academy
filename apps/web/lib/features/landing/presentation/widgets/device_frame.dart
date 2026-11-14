import 'package:material_ui/material_ui.dart';

/// Real screenshots of the redesigned app on the demo mock, one set per
/// language, captured at phone size (360x780 logical, 2x) by `test/golden/landing_screens_capture.dart`.
enum LandingShot {
  liveMatch('live_match'),
  trainingWeek('training_week'),
  playerHealth('player_health'),
  platformUsage('platform_usage');

  const LandingShot(this.fileStem);

  final String fileStem;

  static const _languages = ['es', 'en', 'id'];

  /// The picture in [languageCode] (es, en, id); any other language gets en.
  String assetFor(String languageCode) {
    final code = _languages.contains(languageCode) ? languageCode : 'en';
    return 'assets/landing/${fileStem}_$code.png';
  }

  /// Logical size the screenshots were taken at.
  static const aspectRatio = 360 / 780;
}

/// A phone outline around one [LandingShot].
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.shot,
    required this.width,
    required this.semanticLabel,
    this.onDarkBackground = false,
  });

  final LandingShot shot;
  final double width;
  final String semanticLabel;

  /// Lighter rim so the bezel stays visible on a near-black band.
  final bool onDarkBackground;

  static double _bezel(double width) => width * 0.035;

  /// Outer height of a frame [width] wide.
  static double heightFor(double width) =>
      (width - 2 * _bezel(width)) / LandingShot.aspectRatio + 2 * _bezel(width);

  @override
  Widget build(BuildContext context) {
    final bezel = _bezel(width);
    final outerRadius = width * 0.13;
    final screenWidth = width - 2 * bezel;
    final language = Localizations.localeOf(context).languageCode;
    return Container(
      width: width,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0C),
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: onDarkBackground
              ? const Color(0xFF3A3D42)
              : const Color(0xFF26282C),
          width: 1.5,
        ),
        // No offset: a soft halo in the browser, nothing hard-edged where
        // blur is not rendered (the capture and golden toolchain).
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 36)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outerRadius - bezel),
        child: SizedBox(
          width: screenWidth,
          height: screenWidth / LandingShot.aspectRatio,
          child: Image.asset(
            shot.assetFor(language),
            fit: BoxFit.cover,
            semanticLabel: semanticLabel,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

/// Soft orange light behind a device mock-up.
class AccentGlow extends StatelessWidget {
  const AccentGlow({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}
