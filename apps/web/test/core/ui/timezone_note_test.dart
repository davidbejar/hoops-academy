import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/core/ui/page_layout.dart';
import 'package:hoops_app/core/ui/timezone_note.dart';
import 'package:hoops_app/features/tenant/application/tenant_providers.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('the note lines up with the content of a ContentFrame', (
    tester,
  ) async {
    await pumpKit(
      tester,
      ProviderScope(
        overrides: [
          tenantZoneProvider.overrideWithValue(TenantZone.of('Asia/Jakarta')),
        ],
        child: const ContentFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Semana', key: Key('title')),
              TimezoneNote(),
            ],
          ),
        ),
      ),
      size: const Size(360, 300),
      scaffold: false,
    );
    final note = find.byKey(const Key('timezone-note'));
    expect(note, findsOneWidget);
    expect(
      tester.getTopLeft(note).dx,
      tester.getTopLeft(find.byKey(const Key('title'))).dx,
    );
    expect(tester.getTopLeft(note).dx, WidthClass.compact.gutter);
  });

  testWidgets('nothing while the academy zone is unknown', (tester) async {
    await pumpKit(
      tester,
      ProviderScope(
        overrides: [tenantZoneProvider.overrideWithValue(TenantZone.of(null))],
        child: const TimezoneNote(),
      ),
    );
    expect(find.byKey(const Key('timezone-note')), findsNothing);
  });
}
