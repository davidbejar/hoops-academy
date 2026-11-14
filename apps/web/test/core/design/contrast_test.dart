import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/core/design/tokens.dart';

void main() {
  group('contrastRatio (WCAG 2.x)', () {
    test('black on white is 21:1 and symmetric', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.01));
    });

    test('a colour on itself is 1:1', () {
      expect(
        contrastRatio(const Color(0xFFE8590C), const Color(0xFFE8590C)),
        closeTo(1, 0.0001),
      );
    });

    test('known reference values', () {
      // #777777 on white is the classic just-below-AA grey (4.48:1).
      expect(
        contrastRatio(const Color(0xFF777777), Colors.white),
        closeTo(4.48, 0.01),
      );
      // The landing's white-on-orange button (WP70 handover: about 3.6:1).
      expect(
        contrastRatio(Colors.white, const Color(0xFFE8590C)),
        closeTo(3.56, 0.05),
      );
    });

    test('alpha is composited over the background first', () {
      final half = Colors.black.withValues(alpha: 0.5);
      final ratio = contrastRatio(half, Colors.white);
      expect(ratio, greaterThan(3.5));
      expect(ratio, lessThan(4.5));
    });
  });

  for (final brightness in Brightness.values) {
    final colors = HoopsColors.of(brightness);
    group('${brightness.name} tokens meet AA', () {
      test('every text / background pair is at least 4.5:1', () {
        final failures = [
          for (final p in colors.textPairs)
            if (contrastRatio(p.foreground, p.background) < 4.5)
              '${p.name}: '
                  '${contrastRatio(p.foreground, p.background).toStringAsFixed(2)}',
        ];
        expect(failures, isEmpty);
        expect(colors.textPairs.length, greaterThanOrEqualTo(30));
      });

      test('every control / background pair is at least 3:1 (WCAG 1.4.11)', () {
        final failures = [
          for (final p in colors.controlPairs)
            if (contrastRatio(p.foreground, p.background) < 3)
              '${p.name}: '
                  '${contrastRatio(p.foreground, p.background).toStringAsFixed(2)}',
        ];
        expect(failures, isEmpty);
        expect(colors.controlPairs, isNotEmpty);
      });

      test('the theme ColorScheme on-colours meet AA on their colours', () {
        final s = buildTheme(brightness).colorScheme;
        final pairs = {
          'onPrimary/primary': (s.onPrimary, s.primary),
          'onPrimaryContainer/primaryContainer': (
            s.onPrimaryContainer,
            s.primaryContainer,
          ),
          'onSecondary/secondary': (s.onSecondary, s.secondary),
          'onSecondaryContainer/secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer,
          ),
          'onTertiary/tertiary': (s.onTertiary, s.tertiary),
          'onTertiaryContainer/tertiaryContainer': (
            s.onTertiaryContainer,
            s.tertiaryContainer,
          ),
          'onError/error': (s.onError, s.error),
          'onErrorContainer/errorContainer': (
            s.onErrorContainer,
            s.errorContainer,
          ),
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
          'onSurface/surfaceContainerLow': (s.onSurface, s.surfaceContainerLow),
          'onSurfaceVariant/surfaceContainerHighest': (
            s.onSurfaceVariant,
            s.surfaceContainerHighest,
          ),
          'primary/surface (text buttons)': (s.primary, s.surface),
          'primary/surfaceContainerLow (text buttons in cards)': (
            s.primary,
            s.surfaceContainerLow,
          ),
          'onInverseSurface/inverseSurface (snack bars)': (
            s.onInverseSurface,
            s.inverseSurface,
          ),
          'inversePrimary/inverseSurface (snack bar action)': (
            s.inversePrimary,
            s.inverseSurface,
          ),
        };
        final failures = [
          for (final MapEntry(:key, value: (fg, bg)) in pairs.entries)
            if (contrastRatio(fg, bg) < 4.5)
              '$key: ${contrastRatio(fg, bg).toStringAsFixed(2)}',
        ];
        expect(failures, isEmpty);
      });
    });
  }
}
