import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/navigation/destinations.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

void main() {
  List<AppDestination> nav(
    Set<TenantRole> roles, {
    bool applicationAdmin = false,
  }) => destinationsFor(roles: roles, applicationAdmin: applicationAdmin);

  test('ADMIN sees Admin, Teams, Matches, Training, Players', () {
    expect(nav({TenantRole.admin}), [
      AppDestination.admin,
      AppDestination.teams,
      AppDestination.matches,
      AppDestination.training,
      AppDestination.players,
    ]);
  });

  test('COACH and ASSISTANT_COACH see Teams, Matches, Training, Players', () {
    const expected = [
      AppDestination.teams,
      AppDestination.matches,
      AppDestination.training,
      AppDestination.players,
    ];
    expect(nav({TenantRole.coach}), expected);
    expect(nav({TenantRole.assistantCoach}), expected);
  });

  test('PARENT sees Matches, Training, My players', () {
    expect(nav({TenantRole.parent}), [
      AppDestination.matches,
      AppDestination.training,
      AppDestination.myPlayers,
    ]);
  });

  test('PLAYER sees Matches, Training, Me', () {
    expect(nav({TenantRole.player}), [
      AppDestination.matches,
      AppDestination.training,
      AppDestination.me,
    ]);
  });

  test('the highest role wins when a person holds several', () {
    expect(
      nav({TenantRole.parent, TenantRole.admin}).first,
      AppDestination.admin,
    );
    expect(
      nav({TenantRole.player, TenantRole.coach}).first,
      AppDestination.teams,
    );
  });

  test('the application admin context has its own menu (WP99)', () {
    expect(nav({}, applicationAdmin: true), [
      AppDestination.appAdmin,
      AppDestination.appAcademies,
      AppDestination.appUsers,
      AppDestination.appRequests,
      AppDestination.appActivity,
    ]);
  });

  test('the application admin menu wins over any tenant role', () {
    expect(
      nav({TenantRole.admin}, applicationAdmin: true).first,
      AppDestination.appAdmin,
    );
  });

  test('no roles and no application admin context: no destinations', () {
    expect(nav({}), isEmpty);
  });

  test('home path is the first destination', () {
    expect(
      homePathFor(roles: {TenantRole.parent}, applicationAdmin: false),
      '/matches',
    );
    expect(homePathFor(roles: {}, applicationAdmin: true), '/app-admin');
  });
}
