import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/features/finance/application/finance_rights.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';

/// Who sees which part of the finance area (decision 96, the finance rows of
/// `docs/domain/authz-matrix.md`): UI affordances only, the service decides.
void main() {
  Capabilities caps(
    Set<TenantRole> roles, {
    Set<String> teams = const {},
    Set<String> linked = const {},
    String? own,
  }) => Capabilities(
    roles: roles,
    staffTeamIds: teams,
    linkedPlayerIds: linked,
    ownPlayerId: own,
    personId: 'me',
  );

  api.TeamStaffMember staff(String id, api.StaffRole role) =>
      api.TeamStaffMember(
        (b) => b
          ..person.replace(personRef(id, 'Someone'))
          ..role = role
          ..since = api.Date(2026, 9, 1),
      );

  group('expenses, balance and exports are ADMIN only', () {
    test('every role', () {
      expect(caps({TenantRole.admin}).canManageFinance, isTrue);
      for (final role in [
        TenantRole.coach,
        TenantRole.assistantCoach,
        TenantRole.parent,
        TenantRole.player,
      ]) {
        expect(caps({role}).canManageFinance, isFalse, reason: '$role');
      }
    });

    test('a member with several roles has what any of them gives', () {
      expect(
        caps({TenantRole.coach, TenantRole.admin}).canManageFinance,
        isTrue,
      );
    });
  });

  group("the coach's view of who is up to date", () {
    test('the current COACH of the team, not of another', () {
      final c = caps({TenantRole.coach}, teams: {'t1'});
      expect(c.canSeeTeamDueStatus('t1'), isTrue);
      expect(c.canSeeTeamDueStatus('t2'), isFalse);
    });

    test('a COACH who is only the assistant of this team does not', () {
      final c = caps({TenantRole.coach}, teams: {'t1'});
      expect(
        c.canSeeTeamDueStatus(
          't1',
          staff: [
            staff('me', api.StaffRole.ASSISTANT_COACH),
            staff('other', api.StaffRole.COACH),
          ],
        ),
        isFalse,
      );
      expect(
        c.canSeeTeamDueStatus('t1', staff: [staff('me', api.StaffRole.COACH)]),
        isTrue,
      );
    });

    test('nobody else: assistant, parent, player, a plain ADMIN', () {
      for (final role in [
        TenantRole.assistantCoach,
        TenantRole.parent,
        TenantRole.player,
        TenantRole.admin,
      ]) {
        expect(
          caps({role}, teams: {'t1'}).canSeeTeamDueStatus('t1'),
          isFalse,
          reason: '$role',
        );
      }
    });

    test('a former coach (the team is not in the staff set) does not', () {
      expect(caps({TenantRole.coach}).canSeeTeamDueStatus('t1'), isFalse);
    });
  });

  group("the family's dues", () {
    test('a PARENT of a linked player, a PLAYER of their own', () {
      final parent = caps({TenantRole.parent}, linked: {'p1'});
      expect(parent.canSeeFamilyDues('p1'), isTrue);
      expect(parent.canSeeFamilyDues('p2'), isFalse);
      final player = caps({TenantRole.player}, own: 'p1');
      expect(player.canSeeFamilyDues('p1'), isTrue);
      expect(player.canSeeFamilyDues('p2'), isFalse);
    });

    test('a link without the PARENT role, a coach, an assistant: no', () {
      expect(
        caps({TenantRole.coach}, linked: {'p1'}).canSeeFamilyDues('p1'),
        isFalse,
      );
      expect(
        caps({TenantRole.assistantCoach}, teams: {'t1'}).canSeeFamilyDues('p1'),
        isFalse,
      );
    });
  });
}
