import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart' show member;
import '../../support/fake_repos.dart' show FakeCore, FakeMembersRepository;
import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

/// Decision 73 (WP99): a member edits their own first and last name in the
/// profile, for every role, through `PATCH /me` (the body carries the academy).
Future<Harness> _pump(
  WidgetTester tester, {
  Set<TenantRole> roles = const {TenantRole.coach},
  CurrentUser? user,
  FakeMeRepository? me,
}) async {
  final member = membershipWithRoles(roles);
  final h = Harness(
    me: me ?? FakeMeRepository(user ?? userWith([member])),
    prefs: {'hoops.selectedTenantId': member.tenantId},
  );
  await h.pump(tester);
  await tester.tap(find.byKey(const Key('profile-button')));
  await tester.pumpAndSettle();
  return h;
}

TextField _field(WidgetTester tester, String key) => tester.widget<TextField>(
  find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
);

Future<void> _scrollTo(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  group('the name section', () {
    for (final role in TenantRole.values) {
      testWidgets('is there for ${role.name}, filled with the current name', (
        tester,
      ) async {
        await _pump(tester, roles: {role});
        await _scrollTo(tester, 'profile-given-name');
        expect(_field(tester, 'profile-given-name').controller!.text, 'Casey');
        expect(_field(tester, 'profile-family-name').controller!.text, 'Coach');
      });
    }

    testWidgets('is not shown in the application admin (no academy)', (
      tester,
    ) async {
      final h = Harness(me: FakeMeRepository(userWith([], superAdmin: true)));
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('profile-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-given-name')), findsNothing);
    });

    testWidgets('a family name of several words stays together', (
      tester,
    ) async {
      final user = CurrentUser(
        displayName: 'Ana García López',
        email: 'ana@example.org',
        localeCode: 'es',
        superAdmin: false,
        memberships: [
          membershipWithRoles({TenantRole.parent}),
        ],
      );
      await _pump(tester, user: user);
      await _scrollTo(tester, 'profile-given-name');
      expect(_field(tester, 'profile-given-name').controller!.text, 'Ana');
      expect(
        _field(tester, 'profile-family-name').controller!.text,
        'García López',
      );
    });
  });

  group('saving', () {
    testWidgets('sends only what changed, with the academy, and refreshes', (
      tester,
    ) async {
      final me = FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.coach}),
        ]),
      );
      await _pump(tester, me: me);
      await _scrollTo(tester, 'profile-given-name');
      await enter(tester, 'profile-given-name', 'Carlos');
      await tapKey(tester, 'profile-name-save');

      expect(me.nameUpdates, [
        (
          tenantId: membershipWithRoles({}).tenantId,
          givenName: 'Carlos',
          familyName: null,
        ),
      ]);
      expect(find.text('Nombre actualizado'), findsOneWidget);
      // /me is read again: the profile header shows the new name.
      await tester.scrollUntilVisible(
        find.text('Carlos Coach'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Carlos Coach'), findsOneWidget);
    });

    testWidgets('the academy member list shows the new name afterwards', (
      tester,
    ) async {
      final members = FakeMembersRepository([
        member('person-me', 'Casey Coach', roles: {api.TenantRole.ADMIN}),
      ]);
      final member0 = membershipWithRoles({TenantRole.admin});
      final h = Harness(
        me: FakeMeRepository(userWith([member0])),
        core: FakeCore(members: members),
        prefs: {'hoops.selectedTenantId': member0.tenantId},
      );
      await h.pump(tester);
      await h.go(tester, '/admin/members');
      expect(find.text('Casey Coach'), findsOneWidget);

      await h.go(tester, '/profile');
      await _scrollTo(tester, 'profile-given-name');
      await enter(tester, 'profile-given-name', 'Carlos');
      // The server renames the person; the list must be read again.
      members.members[0] = member(
        'person-me',
        'Carlos Coach',
        roles: {api.TenantRole.ADMIN},
      );
      await tapKey(tester, 'profile-name-save');
      await h.go(tester, '/admin/members');

      expect(find.text('Carlos Coach'), findsOneWidget);
      expect(find.text('Casey Coach'), findsNothing);
    });

    testWidgets('nothing to save while nothing changed', (tester) async {
      final me = FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.player}),
        ]),
      );
      await _pump(tester, me: me);
      await _scrollTo(tester, 'profile-name-save');
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('profile-name-save')),
      );
      expect(button.onPressed, isNull);
      expect(me.nameUpdates, isEmpty);
    });

    testWidgets('an empty name is refused before any call', (tester) async {
      final me = FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.coach}),
        ]),
      );
      await _pump(tester, me: me);
      await _scrollTo(tester, 'profile-given-name');
      await enter(tester, 'profile-given-name', '   ');
      await tapKey(tester, 'profile-name-save');

      expect(find.text('Campo obligatorio'), findsOneWidget);
      expect(me.nameUpdates, isEmpty);
    });

    testWidgets('a name is at most 80 characters', (tester) async {
      await _pump(tester);
      await _scrollTo(tester, 'profile-given-name');
      expect(_field(tester, 'profile-given-name').maxLength, 80);
      expect(_field(tester, 'profile-family-name').maxLength, 80);
    });

    testWidgets('a failure is told, never raw server text', (tester) async {
      final me = FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.coach}),
        ]),
      )..nameError = Exception('boom: English detail');
      await _pump(tester, me: me);
      await _scrollTo(tester, 'profile-given-name');
      await enter(tester, 'profile-family-name', 'Nuevo');
      await tapKey(tester, 'profile-name-save');

      expect(find.textContaining('English detail'), findsNothing);
      expect(find.text('Nombre actualizado'), findsNothing);
      expect(me.nameUpdates, isEmpty);
    });

    testWidgets('offline: the button waits for the connection', (tester) async {
      final h = await _pump(tester);
      h.online.add(false);
      await tester.pumpAndSettle();
      await _scrollTo(tester, 'profile-given-name');
      await enter(tester, 'profile-given-name', 'Carlos');

      expect(
        find.text('Necesitas conexión para cambiar tu nombre'),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('profile-name-save')),
      );
      expect(button.onPressed, isNull);
    });
  });
}
