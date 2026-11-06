import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/responsive_grid.dart';

import '../../support/kit_harness.dart';

void main() {
  test('columns fit the width, at least one, at most maxColumns', () {
    int cols(double w) => ResponsiveGrid.columnsFor(
      w,
      minTileWidth: 160,
      spacing: 12,
      maxColumns: 4,
    );
    expect(cols(100), 1);
    expect(cols(328), 1); // 160 + 12 + 160 = 332 > 328
    expect(cols(332), 2);
    expect(cols(331), 1);
    expect(cols(2000), 4);
  });

  testWidgets('lays the tiles in rows of equal height', (tester) async {
    await pumpKit(
      tester,
      const ResponsiveGrid(
        minTileWidth: 150,
        children: [
          SizedBox(key: Key('a'), height: 40),
          SizedBox(key: Key('b'), height: 80),
          SizedBox(key: Key('c'), height: 20),
        ],
      ),
      size: const Size(360, 400),
    );
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    final c = tester.getRect(find.byKey(const Key('c')));
    expect(a.top, b.top);
    expect(a.height, b.height);
    expect(c.top, greaterThan(a.bottom));
    expect(a.width, b.width);
  });
}
