import 'dart:async';

import 'package:hoops_app/core/api/api.dart' as api;

import 'core_fixtures.dart';
import 'core_seed.dart';
import 'mock_backend.dart';

/// Every fake can be told to fail (any exception) or hang, to cover the
/// error and loading states of the screens.
mixin Faulty {
  Object? failWith;
  bool hang = false;
  final List<String> calls = [];

  Future<T> run<T>(String name, T Function() body) async {
    calls.add(name);
    if (hang) await Completer<void>().future; // never completes
    if (failWith != null) throw failWith!;
    return body();
  }
}

/// The academy's core data of a test, seeded into the backend (ADR-0070), and
/// afterwards what the app did with it.
class FakeCore {
  FakeCore({
    api.TenantProfile? profile,
    api.TenantSettings? settings,
    MembersData? members,
    List<api.Season>? seasons,
    List<api.AgeCategory>? categories,
    TeamsData? teams,
    PlayersData? players,
    this.approvals = const [],
    this.cases = const [],
  }) : profile = profile ?? profileFixture(),
       settings = settings ?? settingsFixture(),
       members = members ?? MembersData([]),
       seasons = seasons ?? [season(seasonId, '2026/27', current: true)],
       categories = categories ?? [u12, u14],
       teams = teams ?? TeamsData(teams: []),
       players = players ?? PlayersData([]);

  /// The academy's profile and settings (`/api/core/tenant`).
  final api.TenantProfile profile;
  final api.TenantSettings settings;

  /// The members and guardian links, then what the app did with them.
  final MembersData members;

  /// The seasons and age categories (`/api/core/seasons`, `/age-categories`).
  final List<api.Season> seasons;
  final List<api.AgeCategory> categories;

  /// The teams (rosters, staff) and players, then what the app did with them.
  final TeamsData teams;
  final PlayersData players;

  /// Approval requests and eligibility cases (`/approval-requests`, `/eligibility-cases`).
  final List<api.ApprovalRequest> approvals;
  final List<api.EligibilityCase> cases;

  /// Seeds everything into [backend] (players before the rosters that assign
  /// them).
  void seed(MockBackend backend) {
    backend
      ..seedProfile(profile)
      ..seedSettings(settings)
      ..seedSeasons(seasons)
      ..seedCategories(categories)
      ..seedApprovals(approvals)
      ..seedCases(cases);
    players.seedInto(backend);
    teams.seedInto(backend);
    members.seedInto(backend);
  }

  /// A backend seeded with this data, for tests of providers without the app.
  MockBackend seededBackend([MockBackend? backend]) {
    final b = backend ?? MockBackend();
    seed(b);
    return b;
  }
}
