import 'dart:typed_data';

import 'package:built_value/serializer.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'mock_backend.dart';

/// A small PNG stands in for an uploaded logo.
final seededLogo = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);

String _wire<T>(T value) =>
    api.standardSerializers.serialize(value, specifiedType: FullType(T))!
        as String;

/// Seeds the academy's core data (ADR-0070) from the generated models the
/// fixtures build (`core_fixtures.dart`), keeping the mock coherent: a roster
/// is the players' team assignments, a team's staff its staff rows.
extension CoreSeed on MockBackend {
  /// The academy's profile; `hasLogo` stores a logo.
  void seedProfile(api.TenantProfile profile) {
    core.profile
      ..clear()
      ..addAll({
        'slug': profile.slug,
        'name': profile.name,
        'timezone': profile.timezone,
        'defaultLocale': _wire(profile.defaultLocale),
        'contactEmail': profile.contactEmail,
        'websiteUrl': profile.websiteUrl,
      });
    core.logo = profile.hasLogo ? seededLogo : null;
  }

  void seedSettings(api.TenantSettings settings) => core.settings
    ..clear()
    ..addAll(coreJson(settings));

  void seedSeasons(Iterable<api.Season> seasons) =>
      core.seasons.addAll(seasons.map(coreJson));

  void seedCategories(Iterable<api.AgeCategory> categories) =>
      core.categories.addAll(categories.map(coreJson));

  void seedTeams(Iterable<api.Team> teams) {
    for (final t in teams) {
      core.teams
        ..removeWhere((x) => x['id'] == t.id)
        ..add(coreJson(t));
    }
  }

  /// Players with their assignments (`teams`).
  void seedPlayers(Iterable<api.Player> players) {
    for (final p in players) {
      core.players
        ..removeWhere((x) => x['id'] == p.id)
        ..add(coreJson(p));
    }
  }

  /// The roster of [teamId]: each entry becomes an assignment of its player
  /// (a player not seeded yet is created from the entry).
  void seedRoster(String teamId, Iterable<api.TeamPlayer> roster) {
    final team = core.teams.where((t) => t['id'] == teamId).firstOrNull;
    for (final tp in roster) {
      var p = core.players.where((x) => x['id'] == tp.player.id).firstOrNull;
      if (p == null) {
        final name = tp.player.displayName;
        p = {
          'id': tp.player.id,
          'personId': 'person-${tp.player.id}',
          'givenName': name.split(' ').first,
          'familyName': name.split(' ').last,
          'displayName': name,
          'birthDate': '2015-03-04',
          'gender': 'MALE',
          'status': _wire(tp.playerStatus),
          'teams': <Object?>[],
          'createdAt': '2026-01-01T00:00:00.000Z',
        };
        core.players.add(p);
      }
      final teams = p['teams']! as List;
      teams
        ..removeWhere((a) => ((a as Map)['team'] as Map)['id'] == teamId)
        ..add({
          'team': {'id': teamId, 'name': team?['name'] ?? teamId},
          'jerseyNumber': tp.jerseyNumber,
          'playUpLevels': tp.playUpLevels,
          'valid': tp.invalidatedAt == null,
        });
    }
  }

  void seedStaff(String teamId, Iterable<api.TeamStaffMember> staff) =>
      (core.staff[teamId] ??= []).addAll(staff.map(coreJson));

  void seedMembers(Iterable<api.Member> members) =>
      core.members.addAll(members.map(coreJson));

  void seedGuardianLinks(Iterable<api.GuardianLink> links) =>
      core.guardianLinks.addAll(links.map(coreJson));

  void seedApprovals(Iterable<api.ApprovalRequest> requests) =>
      core.approvals.addAll(requests.map(coreJson));

  void seedCases(Iterable<api.EligibilityCase> cases) =>
      core.cases.addAll(cases.map(coreJson));

  /// Makes what the mock lets the test user do match [m] (`/me`'s authz):
  /// staff rows on the seeded teams of `staffTeamIds` and
  /// `historicStaffTeamIds`, guardian links to `linkedPlayerIds`, the own
  /// player's person. Rows that already exist are kept.
  void seedMembership(TenantMembership m) {
    final self = selfId;
    final name = [m.givenName, m.familyName].whereType<String>().join(' ');
    final staffRole = m.roles.contains(TenantRole.coach)
        ? 'COACH'
        : 'ASSISTANT_COACH';
    for (final teamId in {...m.staffTeamIds, ...m.historicStaffTeamIds}) {
      final rows = core.staff[teamId] ??= [];
      if (rows.any((s) => (s['person']! as Map)['personId'] == self)) continue;
      rows.add({
        'person': {'personId': self, 'displayName': name},
        'role': staffRole,
        'since': '2026-09-01',
      });
    }
    for (final playerId in m.linkedPlayerIds) {
      final exists = core.guardianLinks.any(
        (l) =>
            (l['guardian']! as Map)['personId'] == self &&
            (l['player']! as Map)['id'] == playerId,
      );
      if (exists) continue;
      final p = core.players.where((p) => p['id'] == playerId).firstOrNull;
      core.guardianLinks.add({
        'id': 'link-me-$playerId',
        'guardian': {'personId': self, 'displayName': name},
        'player': {
          'id': playerId,
          'displayName': p?['displayName'] ?? playerId,
        },
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
    }
    final own = m.ownPlayerId;
    if (own != null) {
      for (final p in core.players.where((p) => p['id'] == own)) {
        p['personId'] = self;
      }
    }
  }
}
