import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/session.dart';

import '../support/fixtures.dart';

void main() {
  group('redirectFor', () {
    test('initialising auth or profile parks on the splash', () {
      expect(
        redirectFor(const SessionState.initializing(), '/matches'),
        '/splash',
      );
      expect(
        redirectFor(const SessionState.loadingProfile(), '/teams'),
        '/splash',
      );
      expect(redirectFor(const SessionState.initializing(), '/splash'), isNull);
    });

    test('signed-out users are sent to /login from any app route', () {
      expect(redirectFor(const SessionState.signedOut(), '/teams'), '/login');
      expect(redirectFor(const SessionState.signedOut(), '/splash'), '/login');
      expect(redirectFor(const SessionState.signedOut(), '/login'), isNull);
    });

    test('signed-out users stay on the landing at / and /welcome (WP70)', () {
      expect(redirectFor(const SessionState.signedOut(), '/'), isNull);
      expect(redirectFor(const SessionState.signedOut(), '/welcome'), isNull);
    });

    test('while auth initialises the landing routes stay put (WP70)', () {
      // The root route shows the splash until the auth status is known, so a
      // cold start at / can still become the landing.
      expect(redirectFor(const SessionState.initializing(), '/'), isNull);
      expect(
        redirectFor(const SessionState.initializing(), '/welcome'),
        isNull,
      );
      expect(
        redirectFor(const SessionState.loadingProfile(), '/'),
        '/splash',
        reason: 'signed in: the splash stays for the profile load',
      );
    });

    test('signed-in sessions leave the landing for the app (WP70)', () {
      final ready = SessionState.ready(
        user: userWith([tenantNorth]),
        membership: tenantNorth,
      );
      expect(redirectFor(ready, '/welcome'), '/admin');
      final picking = SessionState.needsTenant(
        userWith([tenantNorth, tenantSouth]),
      );
      expect(redirectFor(picking, '/'), '/tenants');
      expect(redirectFor(picking, '/welcome'), '/tenants');
    });

    test('a failed profile load stays on the splash (which offers retry)', () {
      expect(
        redirectFor(const SessionState.profileError(), '/matches'),
        '/splash',
      );
    });

    test('several memberships without a selection go to /tenants', () {
      final s = SessionState.needsTenant(userWith([tenantNorth, tenantSouth]));
      expect(redirectFor(s, '/matches'), '/tenants');
      expect(redirectFor(s, '/tenants'), isNull);
    });

    test('a user without memberships and not super_admin sees /no-access', () {
      final s = SessionState.ready(user: userWith([]), membership: null);
      expect(redirectFor(s, '/matches'), '/no-access');
      expect(redirectFor(s, '/no-access'), isNull);
    });

    test('ready users leave splash/login/root for their home', () {
      final s = SessionState.ready(
        user: userWith([tenantNorth]),
        membership: tenantNorth,
      );
      expect(redirectFor(s, '/splash'), '/admin');
      expect(redirectFor(s, '/login'), '/admin');
      expect(redirectFor(s, '/'), '/admin');
    });

    test('ready users cannot open destinations outside their role', () {
      final s = SessionState.ready(
        user: userWith([tenantSouth]),
        membership: tenantSouth,
      );
      expect(redirectFor(s, '/admin'), '/matches');
      expect(redirectFor(s, '/teams'), '/matches');
      expect(redirectFor(s, '/matches'), isNull);
      expect(redirectFor(s, '/my-players'), isNull);
    });

    test('profile and tenants are reachable by every ready user', () {
      final s = SessionState.ready(
        user: userWith([tenantSouth]),
        membership: tenantSouth,
      );
      expect(redirectFor(s, '/profile'), isNull);
      expect(redirectFor(s, '/tenants'), isNull);
    });

    group('application admin (WP99)', () {
      final admin = userWith([], superAdmin: true);
      final inApp = SessionState.ready(
        user: admin,
        membership: null,
        applicationAdmin: true,
      );

      test('a super admin without academies lands on the hub', () {
        expect(redirectFor(inApp, '/login'), '/app-admin');
        expect(redirectFor(inApp, '/splash'), '/app-admin');
        expect(redirectFor(inApp, '/'), '/app-admin');
        expect(redirectFor(inApp, '/teams'), '/app-admin');
        expect(redirectFor(inApp, '/app-admin'), isNull);
      });

      test('every area of the hub is open, with its sub-routes', () {
        for (final path in [
          '/app-admin/academies',
          '/app-admin/academies/t-1',
          '/app-admin/academies/t-1/activity',
          '/app-admin/users',
          '/app-admin/requests',
          '/app-admin/activity',
          '/app-admin/billing',
        ]) {
          expect(redirectFor(inApp, path), isNull, reason: path);
        }
      });

      test('a super admin in an academy context is kept out of the hub', () {
        final user = userWith([tenantNorth], superAdmin: true);
        final inAcademy = SessionState.ready(
          user: user,
          membership: tenantNorth,
        );
        expect(redirectFor(inAcademy, '/app-admin'), '/admin');
        expect(redirectFor(inAcademy, '/admin'), isNull);
      });

      test('a regular member never reaches it', () {
        final s = SessionState.ready(
          user: userWith([tenantSouth]),
          membership: tenantSouth,
        );
        expect(redirectFor(s, '/app-admin/users'), '/matches');
      });

      test('the chooser and the profile stay open in either context', () {
        expect(redirectFor(inApp, '/tenants'), isNull);
        expect(redirectFor(inApp, '/profile'), isNull);
      });
    });

    group('the old /platform links keep working (WP99)', () {
      final inApp = SessionState.ready(
        user: userWith([], superAdmin: true),
        membership: null,
        applicationAdmin: true,
      );

      test('they redirect to the matching application admin screen', () {
        expect(redirectFor(inApp, '/platform'), '/app-admin/academies');
        expect(redirectFor(inApp, '/platform/requests'), '/app-admin/requests');
        expect(redirectFor(inApp, '/platform/activity'), '/app-admin/activity');
        expect(
          redirectFor(inApp, '/platform/t-1'),
          '/app-admin/academies/t-1',
        );
        expect(
          redirectFor(inApp, '/platform/t-1/activity'),
          '/app-admin/academies/t-1/activity',
        );
      });

      test('a signed-out visitor is asked to sign in first', () {
        expect(redirectFor(const SessionState.signedOut(), '/platform'), '/login');
      });

      test('legacyPlatformPath leaves every other path alone', () {
        expect(legacyPlatformPath('/platformer'), isNull);
        expect(legacyPlatformPath('/admin'), isNull);
        expect(legacyPlatformPath('/app-admin'), isNull);
      });
    });
  });
}
