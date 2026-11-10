import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/picker_dialog.dart';

import '../../support/kit_harness.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<List<String>> future, {
    List<String>? picked,
    Widget? header,
  }) async {
    await pumpKit(
      tester,
      Builder(
        builder: (context) => FilledButton(
          key: const Key('open'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => PickerDialog<String>(
              title: 'Asignar a equipo',
              future: future,
              emptyText: 'Sin equipos',
              emptyKey: const Key('empty'),
              intro: 'Elige un equipo',
              header: header,
              itemBuilder: (context, item) => ListTile(
                key: Key('item-$item'),
                title: Text(item),
                onTap: () {
                  picked?.add(item);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
      size: const Size(600, 700),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump();
  }

  testWidgets('loading, then the options under the intro; tap picks', (
    tester,
  ) async {
    final done = Completer<List<String>>();
    final picked = <String>[];
    await open(tester, done.future, picked: picked);
    expect(find.text('Asignar a equipo'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    done.complete(['Sub-14', 'Sub-16']);
    await tester.pump();
    await tester.pump();
    expect(find.text('Elige un equipo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('item-Sub-16')));
    await tester.pumpAndSettle();
    expect(picked, ['Sub-16']);
    expect(find.text('Asignar a equipo'), findsNothing);
  });

  testWidgets('no options shows the empty text', (tester) async {
    await open(tester, Future.value(const []));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('empty')), findsOneWidget);
    expect(find.text('Sin equipos'), findsOneWidget);
  });

  testWidgets('an error shows its message', (tester) async {
    final failing = Completer<List<String>>();
    await open(tester, failing.future);
    failing.completeError(Exception('boom'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Sin equipos'), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('the header sits above the list and Close closes', (
    tester,
  ) async {
    await open(
      tester,
      Future.value(const ['a']),
      header: const TextField(key: Key('search')),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('search')), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(find.text('Asignar a equipo'), findsNothing);
  });
}
