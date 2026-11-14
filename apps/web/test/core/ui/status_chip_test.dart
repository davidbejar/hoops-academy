import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/status_chip.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('shows the label on the tone container colour', (tester) async {
    await pumpKit(
      tester,
      const StatusChip('En directo', tone: HoopsTone.danger),
    );
    expect(find.text('En directo'), findsOneWidget);
    final c = HoopsColors.light;
    expect(
      decorationColorOf(tester, find.text('En directo')),
      c.danger.container,
    );
    expect(
      tester.widget<Text>(find.text('En directo')).style!.color,
      c.danger.onContainer,
    );
  });

  testWidgets('optional icon and live dot', (tester) async {
    await pumpKit(
      tester,
      const StatusChip(
        'Lesionado',
        tone: HoopsTone.warning,
        icon: Icons.healing,
        dot: true,
      ),
    );
    expect(find.byIcon(Icons.healing), findsOneWidget);
    expect(find.byKey(const Key('status-chip-dot')), findsOneWidget);
  });

  testWidgets('every tone renders in dark mode with its own colours', (
    tester,
  ) async {
    await pumpKit(
      tester,
      Wrap(
        children: [for (final t in HoopsTone.values) StatusChip('x', tone: t)],
      ),
      brightness: Brightness.dark,
    );
    final c = HoopsColors.dark;
    final colors = {
      for (final e in find.text('x').evaluate())
        decorationColorOf(tester, find.byWidget(e.widget)),
    };
    expect(colors, {for (final t in HoopsTone.values) c.tone(t).container});
  });
}
