import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/notice_banner.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('message, icon and action on the tone container', (tester) async {
    var taps = 0;
    await pumpKit(
      tester,
      NoticeBanner(
        message: 'Sin conexión',
        icon: Icons.cloud_off,
        tone: HoopsTone.warning,
        action: TextButton(
          key: const Key('act'),
          onPressed: () => taps++,
          child: const Text('Reintentar'),
        ),
      ),
    );
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(
      decorationColorOf(tester, find.text('Sin conexión')),
      HoopsColors.light.warning.container,
    );
    await tester.tap(find.byKey(const Key('act')));
    expect(taps, 1);
  });

  testWidgets('is announced as a live region', (tester) async {
    await pumpKit(tester, const NoticeBanner(message: 'Modo demo'));
    final semantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Modo demo'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.liveRegion, isTrue);
  });
}
