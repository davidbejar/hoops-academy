import 'dart:typed_data';

import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
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

/// What `/api/core/members` and the guardian links hold for a test, and
/// afterwards what the app did with them (ADR-0070). Before the backend is
/// seeded the lists are the seed; once seeded they are read back from the
/// mock, and the other getters from the requests the app sent. Failures go to
/// the backend.
class MembersData {
  MembersData(List<api.Member> members, {List<api.GuardianLink>? links})
    : _members = members,
      _links = links ?? [];

  final List<api.Member> _members;
  final List<api.GuardianLink> _links;
  MockBackend? _backend;

  /// E-mails that already sign in to another academy (linked, no password).
  final Set<String> loginsElsewhere = {};

  static final _api = RegExp('^/api/core/(members|guardian-links)');
  static const _list = '/api/core/members';

  void seedInto(MockBackend backend) {
    _backend = backend;
    backend
      ..seedMembers(_members)
      ..seedGuardianLinks(_links);
    backend.core.loginsElsewhere.addAll(loginsElsewhere);
    if (_hang) backend.hang(_api);
    if (_failWith != null) _inject(_failWith!, _api);
    if (_issueFails != null) _inject(_issueFails!, _issuePath);
  }

  MockBackend get _b => _backend!;

  static T _from<T>(Object? json) =>
      api.standardSerializers.deserialize(json, specifiedType: FullType(T))
          as T;

  List<api.Member> get members => _backend == null
      ? _members
      : [for (final m in _b.core.members) _from<api.Member>(m)];

  List<api.GuardianLink> get links => _backend == null
      ? _links
      : [for (final l in _b.core.guardianLinks) _from<api.GuardianLink>(l)];

  bool _hang = false;
  set hang(bool value) {
    _hang = value;
    if (_backend != null && value) _b.hang(_api);
  }

  Object? _failWith;

  /// Fails every members and guardian-link call (null: heals).
  set failWith(Object? error) {
    _failWith = error;
    if (_backend == null) return;
    error == null ? _b.heal() : _inject(error, _api);
  }

  static final _issuePath = RegExp(r'/temporary-password$');
  Object? _issueFails;

  /// Fails only the issue of a temporary password.
  set issueFails(Object? error) {
    _issueFails = error;
    if (_backend != null && error != null) _inject(error, _issuePath);
  }

  void _inject(Object error, Pattern path) {
    final b = _backend!;
    if (error is AppError) {
      if (error.kind == AppErrorKind.network) return b.networkDown(path);
      final status =
          error.status ??
          switch (error.kind) {
            AppErrorKind.conflict => 409,
            AppErrorKind.timeout => 504,
            AppErrorKind.validation => 422,
            _ => 500,
          };
      return b.fail(path, status: status, code: error.code);
    }
    if (error is DioException) {
      final data = error.response?.data as Map?;
      return b.fail(
        path,
        status: error.response?.statusCode ?? 500,
        code: data?['code'] as String?,
      );
    }
    b.fail(path);
  }

  /// The search text of the last list request.
  String? get lastQuery => _b.lastQuery(_list).text('q');

  /// The last invitation sent, null when none.
  api.InviteMemberRequest? get invited {
    final sent = _b.requestsTo(_list, method: 'POST');
    return sent.isEmpty
        ? null
        : _from<api.InviteMemberRequest>(MockBackend.bodyOf(sent.last));
  }

  /// The password of the last login the mock created for a member.
  String? get newLoginPassword {
    final sent = _b.requests.where(
      (r) =>
          r.method.toUpperCase() == 'POST' &&
          (r.path == _list || _issuePath.hasMatch(r.path)),
    );
    if (sent.isEmpty) return null;
    final a = _b.lastAnswer(sent.last.path, method: 'POST');
    return a is Map ? a['temporaryPassword'] as String? : null;
  }

  /// The people a temporary password was issued for, in order.
  List<String> get reissuedFor => [
    for (final r in _b.requestsTo(_issuePath, method: 'POST'))
      r.path.split('/')[4],
  ];

  /// Every member update as the dialog sent it (a cleared value is null).
  List<
    ({
      String personId,
      String givenName,
      String familyName,
      String? email,
      String? phone,
      api.Date? birthDate,
      api.Gender? gender,
    })
  >
  get updates => [
    for (final r in _b.requestsTo(
      RegExp(r'^/api/core/members/[^/]+$'),
      method: 'PATCH',
    ))
      () {
        final b = MockBackend.bodyOf(r);
        final day = b['birthDate'] as String?;
        return (
          personId: r.path.split('/').last,
          givenName: b['givenName']! as String,
          familyName: b['familyName']! as String,
          email: b['email'] as String?,
          phone: b['phone'] as String?,
          birthDate: day == null ? null : _from<api.Date>(day),
          gender: b['gender'] == null ? null : _from<api.Gender>(b['gender']),
        );
      }(),
  ];

  /// The repository operations the app called, by the fakes' names.
  List<String> get calls => [
    for (final r in _b.requests)
      if (_api.hasMatch(r.path))
        switch ((r.method.toUpperCase(), r.path)) {
          ('GET', '/api/core/guardian-links') => 'links',
          ('POST', '/api/core/guardian-links') => 'addLink',
          ('DELETE', _) when r.path.startsWith('/api/core/guardian-links/') =>
            'removeLink',
          ('GET', _list) => 'list',
          ('POST', _list) => 'invite',
          _ => '${r.method} ${r.path}',
        },
  ];
}
