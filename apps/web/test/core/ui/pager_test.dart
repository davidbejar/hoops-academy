import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/pager.dart';

import '../../support/kit_harness.dart';

void main() {
  IconButton button(WidgetTester tester, String key) =>
      tester.widget<IconButton>(find.byKey(Key(key)));

  testWidgets('page x of y between the two chevrons, by key prefix', (
    tester,
  ) async {
    final asked = <int>[];
    await pumpKit(
      tester,
      Pager(keyPrefix: 'dues', page: 1, totalPages: 3, onPage: asked.add),
    );
    expect(find.text('Página 2 de 3'), findsOneWidget);
    expect(button(tester, 'dues-previous').tooltip, 'Página anterior');
    expect(button(tester, 'dues-next').tooltip, 'Página siguiente');
    await tester.tap(find.byKey(const Key('dues-previous')));
    await tester.tap(find.byKey(const Key('dues-next')));
    expect(asked, [0, 2]);
  });

  testWidgets('no previous on the first page, no next on the last', (
    tester,
  ) async {
    await pumpKit(
      tester,
      Pager(keyPrefix: 'p', page: 0, totalPages: 2, onPage: (_) {}),
    );
    expect(button(tester, 'p-previous').onPressed, isNull);
    expect(button(tester, 'p-next').onPressed, isNotNull);

    await pumpKit(
      tester,
      Pager(keyPrefix: 'p', page: 1, totalPages: 2, onPage: (_) {}),
    );
    expect(button(tester, 'p-previous').onPressed, isNotNull);
    expect(button(tester, 'p-next').onPressed, isNull);
  });

  testWidgets('nothing while the list fits one page', (tester) async {
    for (final total in [0, 1]) {
      await pumpKit(
        tester,
        Pager(keyPrefix: 'p', page: 0, totalPages: total, onPage: (_) {}),
      );
      expect(find.byType(IconButton), findsNothing);
      expect(find.textContaining('Página'), findsNothing);
    }
  });
}
