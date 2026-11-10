import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/features/landing/presentation/landing_theme.dart';

void main() {
  for (final (name, p, c) in [
    ('light', LandingPalette.light, HoopsColors.light),
    ('dark', LandingPalette.dark, HoopsColors.dark),
  ]) {
    test('the $name palette reads the design tokens', () {
      expect(p.background, c.canvas);
      expect(p.surface, c.surface);
      expect(p.text, c.ink);
      expect(p.muted, c.inkMuted);
      expect(p.accentText, c.accent);
    });
  }

  test('the accent is the brand orange', () {
    expect(LandingPalette.accent, HoopsColors.brandOrange);
  });
}
