import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/action_sheet.dart';

import '../../support/kit_harness.dart';

void main() {
  /// Opens the sheet; [onResult] receives what it returns.
  Future<void> open(
    WidgetTester tester, {
    void Function(String?)? onResult,
  }) async {
    await pumpKit(
      tester,
      Builder(
        builder: (context) => FilledButton(
          key: const Key('open'),
          onPressed: () async {
            final result = await showActionSheet<String>(
              context,
              title: 'Jugada',
              actions: const [
                SheetAction(icon: Icons.add, label: 'Canasta', value: 'two'),
                SheetAction(
                  icon: Icons.sports,
                  label: 'Falta',
                  value: 'foul',
                  subtitle: 'Personal',
                ),
                SheetAction(
                  icon: Icons.undo,
                  label: 'Anular',
                  value: 'void',
                  destructive: true,
                ),
                SheetAction(
                  icon: Icons.timer,
                  label: 'Tiempo muerto',
                  value: 'timeout',
                  key: Key('menu-timeout'),
                ),
              ],
            );
            onResult?.call(result);
          },
          child: const Text('open'),
        ),
      ),
      size: const Size(360, 600),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the actions and returns the chosen value', (tester) async {
    final results = <String?>[];
    await open(tester, onResult: results.add);
    expect(find.text('Jugada'), findsOneWidget);
    expect(find.text('Canasta'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.byType(ActionSheetList<String>), findsOneWidget);
    await tester.tap(find.text('Falta'));
    await tester.pumpAndSettle();
    expect(find.text('Canasta'), findsNothing);
    expect(results, ['foul']);
  });

  testWidgets('destructive actions use the danger colour', (tester) async {
    await open(tester);
    final label = tester.widget<Text>(find.text('Anular'));
    expect(label.style!.color, HoopsColors.light.danger.foreground);
    final icon = tester.widget<Icon>(find.byIcon(Icons.undo));
    expect(icon.color, HoopsColors.light.danger.foreground);
  });

  testWidgets('each action is at least a 48 px tap target', (tester) async {
    await open(tester);
    expect(
      tester.getSize(find.byKey(const Key('sheet-action-two'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('an action keeps the key the caller gives it', (tester) async {
    final results = <String?>[];
    await open(tester, onResult: results.add);
    expect(find.byKey(const Key('sheet-action-timeout')), findsNothing);
    await tester.tap(find.byKey(const Key('menu-timeout')));
    await tester.pumpAndSettle();
    expect(results, ['timeout']);
  });
}
