import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/section_card.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('title, subtitle, actions and body on a bordered surface', (
    tester,
  ) async {
    var edits = 0;
    await pumpKit(
      tester,
      SectionCard(
        title: 'Lesiones',
        subtitle: '1 abierta',
        actions: [
          IconButton(
            key: const Key('edit'),
            onPressed: () => edits++,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
        child: const Text('rodilla izquierda'),
      ),
    );
    expect(find.text('Lesiones'), findsOneWidget);
    expect(find.text('1 abierta'), findsOneWidget);
    expect(find.text('rodilla izquierda'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit')));
    expect(edits, 1);
    expect(
      decorationColorOf(tester, find.text('rodilla izquierda')),
      HoopsColors.light.surface,
    );
    final title = tester.widget<Semantics>(
      find
          .ancestor(of: find.text('Lesiones'), matching: find.byType(Semantics))
          .first,
    );
    expect(title.properties.header, isTrue);
  });

  testWidgets('without a title only the body is shown', (tester) async {
    await pumpKit(tester, const SectionCard(child: Text('body')));
    expect(find.text('body'), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
  });

  testWidgets('a CheckboxListTile works inside a card without a Material', (
    tester,
  ) async {
    var checked = false;
    await pumpKit(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SectionCard(
          child: CheckboxListTile(
            key: const Key('tile'),
            value: checked,
            title: const Text('Incluir archivados'),
            onChanged: (v) => setState(() => checked = v!),
          ),
        ),
      ),
      scaffold: false,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('tile')));
    await tester.pump();
    expect(checked, isTrue);
  });
}
