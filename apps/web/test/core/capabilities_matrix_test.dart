import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

/// Every affordance of [Capabilities] per persona (docs/domain/authz-matrix.md;
/// WP88: the matrix the Dart mutation run checks). Teams: t1 current team of
/// the staff personas, t0 a team of an ended season they coached, t2 another
/// team. Players: p1 linked / own, p2 another player.
final _rules = <String, bool Function(Capabilities)>{
  'browseSeasons': (c) => c.canBrowseSeasons,
  'seeModule': (c) => c.canSeeModule,
  'isAdmin': (c) => c.isAdmin,
  'manageAcademy': (c) => c.canManageAcademy,
  'manageTeams': (c) => c.canManageTeams,
  'manageTeam t1': (c) => c.canManageTeam('t1'),
  'manageTeam t2': (c) => c.canManageTeam('t2'),
  'editRoster t1': (c) => c.canEditRoster('t1'),
  'editRoster t2': (c) => c.canEditRoster('t2'),
  'resolveCase t1': (c) => c.canResolveCase('t1'),
  'resolveCase t2': (c) => c.canResolveCase('t2'),
  'createPlayer': (c) => c.canCreatePlayerDirectly,
  'requestPlayer': (c) => c.canRequestPlayer,
  'decideApprovals': (c) => c.canDecideApprovals,
  'seeApprovals': (c) => c.canSeeApprovals,
  'withdrawPlayer': (c) => c.canWithdrawPlayer,
  'runMatch t1': (c) => c.canRunMatch('t1'),
  'runMatch t2': (c) => c.canRunMatch('t2'),
  'linked p1': (c) => c.isLinkedTo('p1'),
  'linked p2': (c) => c.isLinkedTo('p2'),
  'manageTraining t1': (c) => c.canManageTraining('t1'),
  'manageTraining t2': (c) => c.canManageTraining('t2'),
  'readTraining t0': (c) => c.canReadTraining('t0'),
  'readTraining t1': (c) => c.canReadTraining('t1'),
  'readTraining t2': (c) => c.canReadTraining('t2'),
  'manageAnyTraining': (c) => c.canManageAnyTraining,
  'editPlans': (c) => c.canEditPlans,
  'assignPlans': (c) => c.canAssignPlans,
  'absenceFor p1': (c) => c.canFileAbsenceFor('p1'),
  'absenceFor p2': (c) => c.canFileAbsenceFor('p2'),
  'fileAbsences': (c) => c.canFileAbsences,
  'self p1': (c) => c.isSelf('p1'),
  'self p2': (c) => c.isSelf('p2'),
  'completion p1': (c) => c.canMarkCompletion('p1'),
  'completion p2': (c) => c.canMarkCompletion('p2'),
  'writeHealth p1': (c) => c.canWriteHealth('p1'),
  'writeHealth p2': (c) => c.canWriteHealth('p2'),
  'enterTestResults': (c) => c.canEnterTestResults,
  'adminFitness': (c) => c.canAdminFitness,
  'createMatches': (c) => c.canCreateMatches,
};

const _staffEverywhere = {
  'seeModule',
  'readTraining t1',
  'editPlans',
  'absenceFor p1',
  'absenceFor p2',
  'fileAbsences',
  'completion p1',
  'completion p2',
  'writeHealth p1',
  'writeHealth p2',
  'enterTestResults',
};

const _adminAll = {
  ..._staffEverywhere,
  'browseSeasons',
  'isAdmin',
  'manageAcademy',
  'manageTeams',
  'manageTeam t1',
  'manageTeam t2',
  'editRoster t1',
  'editRoster t2',
  'resolveCase t1',
  'resolveCase t2',
  'createPlayer',
  'decideApprovals',
  'seeApprovals',
  'withdrawPlayer',
  'runMatch t1',
  'runMatch t2',
  'manageTraining t1',
  'manageTraining t2',
  'readTraining t0',
  'readTraining t2',
  'manageAnyTraining',
  'assignPlans',
  'adminFitness',
  'createMatches',
};

const _onCurrentTeam = {
  'runMatch t1',
  'manageTraining t1',
  'manageAnyTraining',
  'assignPlans',
  'createMatches',
};

final _personas = <String, (Capabilities, Set<String>)>{
  'ADMIN': (const Capabilities(roles: {TenantRole.admin}), _adminAll),
  'ADMIN viewing a past season': (
    const Capabilities(roles: {TenantRole.admin}, viewingPastSeason: true),
    _adminAll.difference({
      'manageAnyTraining',
      'assignPlans',
      'writeHealth p1',
      'writeHealth p2',
      'enterTestResults',
      'createMatches',
    }),
  ),
  'ADMIN, t1 ended': (
    const Capabilities(roles: {TenantRole.admin}, endedTeamIds: {'t1'}),
    _adminAll.difference({
      'manageTeam t1',
      'editRoster t1',
      'runMatch t1',
      'manageTraining t1',
    }),
  ),
  'COACH of t1, formerly of t0': (
    const Capabilities(
      roles: {TenantRole.coach},
      staffTeamIds: {'t1'},
      historicStaffTeamIds: {'t0'},
    ),
    {
      ..._staffEverywhere,
      ..._onCurrentTeam,
      'browseSeasons',
      'editRoster t1',
      'resolveCase t1',
      'requestPlayer',
      'seeApprovals',
      'withdrawPlayer',
      'readTraining t0',
    },
  ),
  'COACH of t1, t1 ended': (
    const Capabilities(
      roles: {TenantRole.coach},
      staffTeamIds: {'t1'},
      endedTeamIds: {'t1'},
    ),
    {
      ..._staffEverywhere,
      'resolveCase t1',
      'requestPlayer',
      'seeApprovals',
      'withdrawPlayer',
      'manageAnyTraining',
      'assignPlans',
      'createMatches',
    },
  ),
  'COACH and ADMIN': (
    const Capabilities(
      roles: {TenantRole.coach, TenantRole.admin},
      staffTeamIds: {'t1'},
    ),
    _adminAll,
  ),
  'ASSISTANT_COACH of t1': (
    const Capabilities(
      roles: {TenantRole.assistantCoach},
      staffTeamIds: {'t1'},
    ),
    {..._staffEverywhere, ..._onCurrentTeam},
  ),
  'ASSISTANT_COACH formerly of t0 only': (
    const Capabilities(
      roles: {TenantRole.assistantCoach},
      historicStaffTeamIds: {'t0'},
    ),
    {
      ..._staffEverywhere.difference({'readTraining t1'}),
      'browseSeasons',
      'readTraining t0',
    },
  ),
  'PARENT of p1': (
    const Capabilities(roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}),
    {
      'linked p1',
      'absenceFor p1',
      'fileAbsences',
      'completion p1',
      'writeHealth p1',
    },
  ),
  'PARENT of p1 viewing a past season': (
    const Capabilities(
      roles: {TenantRole.parent},
      linkedPlayerIds: {'p1'},
      viewingPastSeason: true,
    ),
    {'linked p1', 'absenceFor p1', 'fileAbsences', 'completion p1'},
  ),
  'PLAYER p1': (
    const Capabilities(roles: {TenantRole.player}, ownPlayerId: 'p1'),
    {'self p1', 'absenceFor p1', 'fileAbsences', 'completion p1'},
  ),
  'links and an own player without the roles': (
    const Capabilities(roles: {}, linkedPlayerIds: {'p2'}, ownPlayerId: 'p1'),
    {'fileAbsences'},
  ),
  'a member without roles': (const Capabilities(roles: {}), <String>{}),
};

void main() {
  for (final MapEntry(key: persona, value: (caps, allowed))
      in _personas.entries) {
    test(persona, () {
      final actual = {
        for (final MapEntry(key: rule, value: check) in _rules.entries)
          if (check(caps)) rule,
      };
      expect(actual, allowed);
    });
  }

  test('none is the empty capability set', () {
    expect(Capabilities.none, const Capabilities(roles: {}));
    expect(Capabilities.none.viewingPastSeason, isFalse);
  });

  test(
    'equal capabilities are equal with the same hash; any field differs',
    () {
      Capabilities make({
        Set<TenantRole> roles = const {TenantRole.coach},
        Set<String> staff = const {'t1'},
        Set<String> historic = const {'t0'},
        Set<String> ended = const {'t9'},
        bool past = false,
        Set<String> linked = const {'p1'},
        String? person = 'me',
        String? own = 'p1',
      }) => Capabilities(
        roles: roles,
        staffTeamIds: staff,
        historicStaffTeamIds: historic,
        endedTeamIds: ended,
        viewingPastSeason: past,
        linkedPlayerIds: linked,
        personId: person,
        ownPlayerId: own,
      );
      final base = make();
      expect(make(), base);
      expect(make().hashCode, base.hashCode);
      final variants = [
        make(roles: {TenantRole.admin}),
        make(staff: {'t2'}),
        make(historic: {}),
        make(ended: {}),
        make(past: true),
        make(linked: {}),
        make(person: 'other'),
        make(own: null),
      ];
      for (final v in variants) {
        expect(v, isNot(base));
        expect(v.hashCode, isNot(base.hashCode));
      }
      expect(base == Object(), isFalse);
    },
  );
}
