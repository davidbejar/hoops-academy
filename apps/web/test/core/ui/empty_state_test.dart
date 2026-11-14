import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/empty_state.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('icon tile, title, message and action', (tester) async {
    var taps = 0;
    await pumpKit(
      tester,
      EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Sin entrenamientos',
        message: 'Crea la primera sesión de la semana.',
        action: FilledButton(
          key: const Key('cta'),
          onPressed: () => taps++,
          child: const Text('Nueva sesión'),
        ),
      ),
      size: const Size(360, 400),
    );
    expect(find.text('Sin entrenamientos'), findsOneWidget);
    expect(find.text('Crea la primera sesión de la semana.'), findsOneWidget);
    expect(
      decorationColorOf(tester, find.byIcon(Icons.event_busy_outlined)),
      HoopsColors.light.accentSoft,
    );
    await tester.tap(find.byKey(const Key('cta')));
    expect(taps, 1);
  });

  testWidgets('a danger tone for error states', (tester) async {
    await pumpKit(
      tester,
      const EmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        tone: HoopsTone.danger,
      ),
      brightness: Brightness.dark,
    );
    expect(
      decorationColorOf(tester, find.byIcon(Icons.error_outline)),
      HoopsColors.dark.danger.container,
    );
  });
}
