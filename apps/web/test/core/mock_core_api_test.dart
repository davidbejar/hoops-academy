import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/admin/data/academy_repository.dart';
import 'package:hoops_app/features/admin/data/age_categories_repository.dart';
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/admin/data/seasons_repository.dart';
import 'package:hoops_app/features/audit/data/audit_repository.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';
import 'package:hoops_app/features/roster/data/approvals_repository.dart';
import 'package:hoops_app/features/roster/data/cases_repository.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

/// The demo backend must be indistinguishable from the contract for the
/// generated client: every call below deserialises through `hoops_core_api`.
void main() {
  late api.HoopsCoreApi client;
  const t = mockTenantAId;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}))
      ..httpClientAdapter = MockApiAdapter(roles: ['ADMIN']);
    client = api.HoopsCoreApi(dio: dio, interceptors: const []);
  });

  test('profile, settings, logo upload / fetch / delete', () async {
    final academy = ApiAcademyRepository(client, t);
    expect((await academy.profile()).name, 'Academia Demo');
    expect((await academy.settings()).maxPlayUpLevels, 1);

    final saved = await academy.save(
      profile: api.UpdateTenantProfileRequest((b) => b.name = 'Club Mock'),
      settings: (await academy.settings()).rebuild((b) => b.maxPlayUpLevels = 2),
    );
    expect(saved.name, 'Club Mock');
    expect((await academy.settings()).maxPlayUpLevels, 2);

    final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 9, 9, 9]);
    final logo = await academy.uploadLogo(bytes: bytes, mimeType: 'image/png', fileName: 'l.png');
    expect(logo.sizeBytes, bytes.length);
    final fetched = await client.getTenantApi().getTenantLogo(xTenantId: t);
    expect(fetched.data, bytes);
    await academy.deleteLogo();
    expect((await academy.profile()).hasLogo, isFalse);
  });

  test('the activity trail deserialises with every actor kind (WP34)', () async {
    final page = await ApiAuditRepository(client).academy(t, const AuditQuery());
    expect(page.items, isNotEmpty);
    expect(page.items.map((e) => e.actorKind).toSet(), {
      api.AuditActorKind.PERSON,
      api.AuditActorKind.SYSTEM,
      api.AuditActorKind.PLATFORM,
    });
    expect(page.items.first.action, api.AuditAction.memberPeriodInvited);
  });

  test('seasons, categories, rollover with orphans and opened cases', () async {
    final seasons = ApiSeasonsRepository(client, t);
    expect((await seasons.list()).where((s) => s.current).single.name, '2026/27');
    final created = await seasons.create(
      name: '2027/28', startsOn: api.Date(2027, 9, 1), endsOn: api.Date(2028, 6, 30), referenceYear: 2027,
    );
    expect(created.name, '2027/28');

    final result = await seasons.rollover('season-2026');
    expect(result.clonedTeams, isNotEmpty);
    expect(result.orphans.map((o) => o.player.displayName), contains('Leo Gil'));
    expect(result.openedCaseIds.length, result.orphans.length);

    final cats = ApiAgeCategoriesRepository(client, t);
    final c = await cats.create(code: 'U18', name: 'Junior', rank: 5);
    expect(c.maxAge, isNull);
    await cats.delete(c.id);
    expect((await cats.list()).length, 4);
  });

  test('members, invitation and guardian links', () async {
    final members = ApiMembersRepository(client, t);
    expect((await members.list(query: 'pat')).single.roles, contains(api.TenantRole.PARENT));
    final invited = await members.invite(
      api.InviteMemberRequest((b) => b
        ..givenName = 'Nora'
        ..familyName = 'Vega'
        ..email = 'nora@x.io'
        ..roles.replace([api.TenantRole.COACH])),
    );
    expect(invited.invitationStatus, api.InvitationStatus.PENDING);
    expect(invited.temporaryPassword, isNotEmpty); // like the server: returned once for a login the call created
    expect((await members.list(query: 'nora')).single, isNot(isA<api.MemberWithPassword>()));
    final reissued = await members.issueTemporaryPassword(invited.personId);
    expect(reissued.temporaryPassword, isNotEmpty);
    expect(reissued.temporaryPassword, isNot(invited.temporaryPassword));
    await members.deactivate(invited.personId);
    expect((await members.list(active: true)).any((m) => m.personId == invited.personId), isFalse);

    final links = await members.guardianLinks(guardianPersonId: 'm-pat');
    expect(links.single.player.displayName, 'Ana Ruiz');
    final added = await members.addGuardianLink(guardianPersonId: 'm-pat', playerId: 'p-leo');
    await members.removeGuardianLink(added.id);
    expect((await members.guardianLinks(guardianPersonId: 'm-pat')).length, 1);
  });

  test('teams: roster, eligibility with play-up, ineligible assignment is a 422', () async {
    final teams = ApiTeamsRepository(client, t);
    final list = await teams.list(seasonId: 'season-2026');
    expect(list.map((x) => x.name), containsAll(['Mini A', 'Mini B', 'Infantil A']));
    expect((await teams.roster('team-mini-a')).length, 2);
    expect((await teams.staff('team-mini-a')).single.role, api.StaffRole.COACH);

    // Mía (2016, female) is U10-age: playing in Mini B (U12) is one level up.
    final up = await teams.checkEligibility('team-mini-b', 'p-mia');
    expect(up.result, api.EligibilityResult.PLAY_UP);
    final leoInfantil = await teams.checkEligibility('team-inf-a', 'p-leo');
    expect(leoInfantil.result, api.EligibilityResult.PLAY_UP);
    expect(leoInfantil.playUpLevels, 1);
    final leoMiniB = await teams.checkEligibility('team-mini-b', 'p-leo');
    expect(leoMiniB.result, api.EligibilityResult.INELIGIBLE);
    expect(leoMiniB.reasons, contains(api.EligibilityReason.GENDER_POLICY));

    await expectLater(
      teams.assign('team-mini-b', 'p-leo'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 422)),
    );
    final assigned = await teams.assign('team-inf-a', 'p-leo', jerseyNumber: '3');
    expect(assigned.playUpLevels, 1);
    await teams.setJersey('team-inf-a', 'p-leo', '8');
    await teams.unassign('team-inf-a', 'p-leo');
  });

  test('players: filters, create (admin = direct), eligible teams, withdraw', () async {
    final players = ApiPlayersRepository(client, t);
    expect((await players.list(status: api.PlayerStatus.ORPHAN)).single.displayName, 'Eva Mar');
    expect((await players.list(teamId: 'team-mini-a')).length, 2);

    final created = await players.create(
      api.CreatePlayerRequest((b) => b
        ..givenName = 'Noa'
        ..familyName = 'Prieto'
        ..birthDate = api.Date(2015, 5, 5)
        ..gender = api.Gender.FEMALE
        ..teamId = 'team-mini-a'),
    );
    expect(created.approvalRequest.status, api.ApprovalStatus.APPROVED);
    expect(created.player.status, api.PlayerStatus.ACTIVE);

    final eligible = await players.eligibleTeams('p-eva', 'season-2026');
    expect(eligible, isNotEmpty);
    final withdrawn = await players.withdraw(created.player.id, reason: 'x');
    expect(withdrawn.player.status, api.PlayerStatus.WITHDRAWN);
  });

  test('approvals and cases', () async {
    final approvals = ApiApprovalsRepository(client, t);
    final pending = await approvals.list(status: api.ApprovalStatus.PENDING);
    expect(pending.length, 2);
    expect((await approvals.approve('ap-1', note: 'ok')).status, api.ApprovalStatus.APPROVED);
    expect((await approvals.reject('ap-2', note: 'no')).decisionNote, 'no');
    await expectLater(approvals.cancel('ap-1'), throwsA(isA<DioException>()));

    final cases = ApiCasesRepository(client, t);
    final open = await cases.list(status: api.EligibilityCaseStatus.OPEN);
    expect(open.single.reason, api.EligibilityReason.CATEGORY_TOO_LOW);
    final done = await cases.resolve(open.single.id,
        resolution: api.EligibilityCaseResolution.REASSIGNED, targetTeamId: 'team-inf-a');
    expect(done.status, api.EligibilityCaseStatus.RESOLVED);
  });

  test('requires the tenant header and bearer like the real service', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = MockApiAdapter();
    await expectLater(dio.get<Object>('/api/core/teams'), throwsA(isA<DioException>()));
  });
}
