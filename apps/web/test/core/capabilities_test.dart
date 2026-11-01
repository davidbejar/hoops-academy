import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

void main() {
  Capabilities caps(Set<TenantRole> roles, {Set<String> teams = const {}}) =>
      Capabilities(roles: roles, staffTeamIds: teams, personId: 'p1');

  test('ADMIN can do everything', () {
    final c = caps({TenantRole.admin});
    expect(c.canManageAcademy, isTrue);
    expect(c.canManageTeams, isTrue);
    expect(c.canEditRoster('any'), isTrue);
    expect(c.canCreatePlayerDirectly, isTrue);
    expect(c.canDecideApprovals, isTrue);
    expect(c.canRequestPlayer, isFalse);
    expect(c.canResolveCase('any'), isTrue);
  });

  test('COACH edits only the roster of own teams and requests players', () {
    final c = caps({TenantRole.coach}, teams: {'t1'});
    expect(c.canManageAcademy, isFalse);
    expect(c.canEditRoster('t1'), isTrue);
    expect(c.canEditRoster('t2'), isFalse);
    expect(c.canResolveCase('t2'), isFalse);
    expect(c.canRequestPlayer, isTrue);
    expect(c.canCreatePlayerDirectly, isFalse);
    expect(c.canDecideApprovals, isFalse);
    expect(c.canSeeApprovals, isTrue);
  });

  test('ASSISTANT_COACH is read-only', () {
    final c = caps({TenantRole.assistantCoach}, teams: {'t1'});
    expect(c.canEditRoster('t1'), isFalse);
    expect(c.canRequestPlayer, isFalse);
    expect(c.canSeeApprovals, isFalse);
    expect(c.canSeeModule, isTrue);
  });

  test('PARENT and PLAYER never see the module', () {
    expect(caps({TenantRole.parent}).canSeeModule, isFalse);
    expect(caps({TenantRole.player}).canSeeModule, isFalse);
  });
}
