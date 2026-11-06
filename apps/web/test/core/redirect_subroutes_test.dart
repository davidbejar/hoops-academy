import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/session.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fixtures.dart';

SessionState _as(Set<TenantRole> roles) {
  final m = membershipWithRoles(roles);
  return SessionState.ready(user: userWith([m]), membership: m);
}

void main() {
  test('sub-routes follow their destination\'s role check', () {
    expect(redirectFor(_as({TenantRole.admin}), '/admin/members'), isNull);
    expect(redirectFor(_as({TenantRole.admin}), '/teams/abc'), isNull);
    expect(redirectFor(_as({TenantRole.coach}), '/players/requests'), isNull);
    expect(
      redirectFor(_as({TenantRole.assistantCoach}), '/teams/cases'),
      isNull,
    );
  });

  test(
    'coach cannot open admin sub-routes; parent/player cannot open roster',
    () {
      expect(redirectFor(_as({TenantRole.coach}), '/admin/profile'), '/teams');
      expect(redirectFor(_as({TenantRole.parent}), '/players/new'), '/matches');
      expect(redirectFor(_as({TenantRole.player}), '/teams/abc'), '/matches');
    },
  );

  test(
    'a path that merely starts with a destination name is not a sub-route',
    () {
      expect(redirectFor(_as({TenantRole.coach}), '/teamsX'), '/teams');
    },
  );
}
