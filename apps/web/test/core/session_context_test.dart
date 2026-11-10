import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/session.dart';

import '../support/fixtures.dart';

/// Which context a login opens in (WP99, decision 71): the contexts are the
/// academies of the login plus "Application admin" for a super admin.
void main() {
  group('contextsOf', () {
    test('a super admin gets Application admin first, then each academy', () {
      final user = userWith([tenantNorth, tenantSouth], superAdmin: true);
      final contexts = contextsOf(user);
      expect(contexts.map((c) => c.id), [
        platformContextId,
        tenantNorth.tenantId,
        tenantSouth.tenantId,
      ]);
      expect(contexts.first, isA<ApplicationAdminContext>());
      expect(contexts[1], isA<AcademyContext>());
    });

    test('a plain member only has academies', () {
      final contexts = contextsOf(userWith([tenantNorth]));
      expect(contexts.map((c) => c.id), [tenantNorth.tenantId]);
    });
  });

  group('sessionFor: the landing', () {
    test('a super admin without academies lands in Application admin', () {
      final s = sessionFor(userWith([], superAdmin: true), null);
      expect(s, isA<Ready>());
      expect((s as Ready).applicationAdmin, isTrue);
      expect(s.membership, isNull);
    });

    test('exactly one academy is entered without asking', () {
      final s = sessionFor(userWith([tenantNorth]), null) as Ready;
      expect(s.applicationAdmin, isFalse);
      expect(s.membership, tenantNorth);
    });

    test('several contexts and nothing remembered: the switcher', () {
      expect(
        sessionFor(userWith([tenantNorth, tenantSouth]), null),
        isA<NeedsTenant>(),
      );
    });

    test('a super admin who is also a member of one academy has two '
        'contexts: the switcher until one is remembered', () {
      final user = userWith([tenantNorth], superAdmin: true);
      expect(sessionFor(user, null), isA<NeedsTenant>());
      final remembered = sessionFor(user, tenantNorth.tenantId) as Ready;
      expect(remembered.membership, tenantNorth);
    });

    test('the remembered context is entered (academy)', () {
      final s = sessionFor(
        userWith([tenantNorth, tenantSouth]),
        tenantSouth.tenantId,
      ) as Ready;
      expect(s.membership, tenantSouth);
    });

    test('the remembered context is entered (Application admin)', () {
      final s = sessionFor(
        userWith([tenantNorth, tenantSouth], superAdmin: true),
        platformContextId,
      ) as Ready;
      expect(s.applicationAdmin, isTrue);
      expect(s.membership, isNull);
      expect(s.roles, isEmpty);
    });

    test('a remembered context that is no longer valid is ignored', () {
      final several = userWith([tenantNorth, tenantSouth]);
      expect(sessionFor(several, 'gone'), isA<NeedsTenant>());
      // "platform" remembered by someone who is no longer a super admin.
      expect(sessionFor(several, platformContextId), isA<NeedsTenant>());
      final single = sessionFor(userWith([tenantNorth]), platformContextId);
      expect((single as Ready).membership, tenantNorth);
    });

    test('no context at all: ready without access', () {
      final s = sessionFor(userWith([]), null) as Ready;
      expect(s.membership, isNull);
      expect(s.applicationAdmin, isFalse);
    });
  });
}
