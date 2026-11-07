import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/fixtures.dart';
import '../../support/harness.dart';

/// Names and e-mail are edited through the member record, which only an ADMIN may do (core contract); the language
/// is the one self-service preference (`PATCH /me`, covered in `locale_test`).
Future<Harness> _pump(WidgetTester tester, Set<TenantRole> roles) async {
  final member = membershipWithRoles(roles);
  final h = Harness(
    me: FakeMeRepository(userWith([member])),
    prefs: {'hoops.selectedTenantId': member.tenantId},
  );
  await h.pump(tester);
  await tester.tap(find.byKey(const Key('profile-button')));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('an admin opens the own member record to edit the name', (
    tester,
  ) async {
    final h = await _pump(tester, {TenantRole.admin});
    final entry = find.byKey(const Key('profile-own-data'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(
      h.container.read(routerProvider).state.uri.path,
      '/admin/members/person-me',
    );
  });

  testWidgets('a coach has no member record to edit: no entry', (tester) async {
    await _pump(tester, {TenantRole.coach});
    expect(find.byKey(const Key('profile-own-data')), findsNothing);
  });
}
