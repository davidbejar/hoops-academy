import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Meaning of a coloured element (chips, banners, tiles). Features pick a
/// tone; the colours come from [HoopsColors.tone].
enum HoopsTone { neutral, accent, success, warning, danger, info }

/// The three colours of a tone: [foreground] for text or icons on the page or
/// a card, and a [container] fill with its [onContainer] text colour.
@immutable
class ToneColors {
  const ToneColors({
    required this.foreground,
    required this.container,
    required this.onContainer,
  });

  final Color foreground;
  final Color container;
  final Color onContainer;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
    container: Color.lerp(a.container, b.container, t)!,
    onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
  );
}
