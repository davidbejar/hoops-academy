import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/features/match/domain/scoring_rights.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

void main() {
  ScoringRights rights(
    Set<TenantRole> roles, {
    Set<String> staff = const {},
    Set<String> linked = const {},
    String? own,
  }) => ScoringRights.of(
    Capabilities(
      roles: roles,
      staffTeamIds: staff,
      linkedPlayerIds: linked,
      personId: 'me',
      ownPlayerId: own,
    ),
    teamId: 'team-a',
  );

  test('ADMIN and staff of the team run the match and score anybody', () {
    for (final r in [
      rights({TenantRole.admin}),
      rights({TenantRole.coach}, staff: {'team-a'}),
      rights({TenantRole.assistantCoach}, staff: {'team-a'}),
    ]) {
      expect(r.canRunMatch, isTrue);
      expect(r.parentMode, isFalse);
      expect(r.canRecordFor('any'), isTrue);
      expect(r.canVoid(recordedByMe: false), isTrue);
    }
  });

  test('coach of another team is read-only', () {
    final r = rights({TenantRole.coach}, staff: {'team-b'});
    expect(r.canRunMatch, isFalse);
    expect(r.canScore, isFalse);
    expect(r.canRecordFor('p1'), isFalse);
  });

  test(
    'PARENT: linked players only, own VOIDs only, never clock/period/opponent',
    () {
      final r = rights({TenantRole.parent}, linked: {'p1'});
      expect(r.parentMode, isTrue);
      expect(r.canScore, isTrue);
      expect(r.canRunMatch, isFalse);
      expect(r.canRecordFor('p1'), isTrue);
      expect(r.canRecordFor('p2'), isFalse);
      expect(r.canVoid(recordedByMe: true), isTrue);
      expect(r.canVoid(recordedByMe: false), isFalse);
      expect(r.canSeeLine('p1'), isTrue);
      expect(r.canSeeLine('p2'), isFalse);
    },
  );

  test('PLAYER and a parent without links are read-only', () {
    expect(rights({TenantRole.player}).canScore, isFalse);
    expect(rights({TenantRole.parent}).canScore, isFalse);
  });

  test(
    'PLAYER sees their own line and no other player\'s, and still cannot score',
    () {
      final r = rights({TenantRole.player}, own: 'p1');
      expect(r.canSeeLine('p1'), isTrue);
      expect(r.canSeeLine('p2'), isFalse);
      expect(r.canScore, isFalse);
      expect(r.canRecordFor('p1'), isFalse);
    },
  );
}
