import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('shows a banner while offline and hides it when back online', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([membershipWithRoles({TenantRole.coach})])));
    await h.pump(tester);
    expect(find.byKey(const Key('offline-banner')), findsNothing);

    h.online.add(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.textContaining('Sin conexión'), findsOneWidget);

    h.online.add(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });
}
