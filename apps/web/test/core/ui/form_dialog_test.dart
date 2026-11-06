import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/form_dialog.dart';

import '../../support/kit_harness.dart';

void main() {
  Future<List<bool?>> open(
    WidgetTester tester,
    Future<bool> Function() onSubmit,
  ) async {
    final results = <bool?>[];
    final formKey = GlobalKey<FormState>();
    await pumpKit(
      tester,
      Builder(
        builder: (context) => FilledButton(
          key: const Key('open'),
          onPressed: () async => results.add(
            await showDialog<bool>(
              context: context,
              builder: (_) => FormDialog(
                title: 'Nuevo equipo',
                formKey: formKey,
                onSubmit: onSubmit,
                children: [
                  TextFormField(
                    key: const Key('name'),
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => (v ?? '').isEmpty ? 'Obligatorio' : null,
                  ),
                ],
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
      size: const Size(360, 640),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('validates before submitting', (tester) async {
    var calls = 0;
    await open(tester, () async {
      calls++;
      return true;
    });
    expect(find.text('Nuevo equipo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Obligatorio'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('closes with true on success, stays open on failure', (
    tester,
  ) async {
    var ok = false;
    final results = await open(tester, () async => ok);
    await tester.enterText(find.byKey(const Key('name')), 'Mini B');
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo equipo'), findsOneWidget);
    ok = true;
    await tester.tap(find.byKey(const Key('form-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo equipo'), findsNothing);
    expect(results, [true]);
  });

  testWidgets('cancel closes with false', (tester) async {
    final results = await open(tester, () async => true);
    await tester.tap(find.byKey(const Key('form-cancel')));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });
}
