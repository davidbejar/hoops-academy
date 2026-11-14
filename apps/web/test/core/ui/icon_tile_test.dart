import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/kit.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('draws the icon on the tone container, in light and dark', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpKit(
        tester,
        const IconTile(Icons.history, tone: HoopsTone.info),
        brightness: brightness,
      );
      final colors = HoopsTokens.colorsOf(tester.element(find.byType(IconTile)))
          .tone(HoopsTone.info);
      expect(
        decorationColorOf(tester, find.byIcon(Icons.history)),
        colors.container,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.history)).color,
        colors.onContainer,
      );
    }
  });

  testWidgets('size sets the square', (tester) async {
    await pumpKit(tester, const IconTile(Icons.history, size: 56));
    expect(tester.getSize(find.byType(IconTile)), const Size.square(56));
  });
}
