import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/stat_tile.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('value, label, caption and the tone icon tile', (tester) async {
    await pumpKit(
      tester,
      const SizedBox(
        width: 180,
        child: StatTile(
          label: 'Asistencia',
          value: '92 %',
          icon: Icons.event_available,
          caption: '+4 vs. mes pasado',
          tone: HoopsTone.success,
        ),
      ),
    );
    expect(find.text('92 %'), findsOneWidget);
    expect(find.text('Asistencia'), findsOneWidget);
    expect(find.text('+4 vs. mes pasado'), findsOneWidget);
    expect(
      decorationColorOf(tester, find.byIcon(Icons.event_available)),
      HoopsColors.light.success.container,
    );
    final value = tester.widget<Text>(find.text('92 %'));
    expect(value.style!.fontWeight, FontWeight.w800);
  });

  testWidgets('reads as one semantic node: label then value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, const StatTile(label: 'Jugadores', value: '42'));
    expect(find.bySemanticsLabel(RegExp('Jugadores.*42')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tappable when onTap is set', (tester) async {
    var taps = 0;
    await pumpKit(
      tester,
      StatTile(
        key: const Key('tile'),
        label: 'Partidos',
        value: '3',
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.byKey(const Key('tile')));
    expect(taps, 1);
  });
}
