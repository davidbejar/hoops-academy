import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/async_body.dart';
import 'package:hoops_app/core/ui/empty_state.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('an empty list renders the kit EmptyState with its action', (
    tester,
  ) async {
    await pumpKit(
      tester,
      SizedBox(
        height: 400,
        width: 328,
        child: AsyncBody<List<int>>(
          value: const AsyncData([]),
          onRetry: () {},
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'Sin equipos',
          emptyAction: const Text('Crear equipo', key: Key('cta')),
          builder: (context, data) => const Text('lleno'),
        ),
      ),
      size: const Size(360, 480),
    );
    expect(find.text('lleno'), findsNothing);
    final empty = find.byType(EmptyState);
    expect(empty, findsOneWidget);
    expect(find.text('Sin equipos'), findsOneWidget);
    expect(
      find.descendant(of: empty, matching: find.byKey(const Key('cta'))),
      findsOneWidget,
    );
  });
}
