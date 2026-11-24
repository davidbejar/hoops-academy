import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/api.dart' show tenantIdProvider;
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/data/local/match_database.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/match/data/mock_game_api.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import 'fake_timers.dart';
import 'mock_backend.dart';

const teamA = 'team-a';

gen.Match gameMatch(
  String id, {
  gen.MatchStatus? status,
  String teamId = teamA,
  String seasonId = 'season-1',
  String opponent = 'Tigres',
  DateTime? at,
}) => gen.Match(
  (b) => b
    ..id = id
    ..teamId = teamId
    ..seasonId = seasonId
    ..opponentName = opponent
    ..homeAway = gen.HomeAway.HOME
    ..scheduledAt = at ?? DateTime.utc(2026, 11, 7, 10)
    ..status = status ?? gen.MatchStatus.LIVE
    ..periodCount = 4
    ..periodMinutes = 10
    ..score.team = 0
    ..score.opponent = 0
    ..lastServerSeq = 0,
);

const demoRoster = [
  RosterPlayer(
    playerId: 'p1',
    displayName: 'Ana Ruiz',
    jerseyNumber: '4',
    isStarter: true,
  ),
  RosterPlayer(
    playerId: 'p2',
    displayName: 'Bo Gil',
    jerseyNumber: '5',
    isStarter: true,
  ),
  RosterPlayer(
    playerId: 'p3',
    displayName: 'Cai Soto',
    jerseyNumber: '6',
    isStarter: true,
  ),
  RosterPlayer(
    playerId: 'p4',
    displayName: 'Dee Mar',
    jerseyNumber: '7',
    isStarter: true,
  ),
  RosterPlayer(
    playerId: 'p5',
    displayName: 'Eli Paz',
    jerseyNumber: '8',
    isStarter: true,
  ),
  RosterPlayer(
    playerId: 'p6',
    displayName: 'Fay Rey',
    jerseyNumber: '9',
    isStarter: false,
  ),
  RosterPlayer(
    playerId: 'p7',
    displayName: 'Gus Luz',
    jerseyNumber: '10',
    isStarter: false,
  ),
];

/// The game side of a test (ADR-0070): the matches, rosters and events
/// seeded into the backend's game mock (the app's repository and events
/// remote talk to it), the device's offline store (an in-memory Drift
/// database) and the sync worker's timers, fired by hand. Afterwards it
/// reads what the app sent and what the mock stored; failures the mock
/// cannot produce are injected in front of it.
class GameData {
  GameData({
    List<gen.Match> matches = const [],
    Map<String, List<RosterPlayer>> rosters = const {},
  }) : _matches = [...matches],
       _rosters = {...rosters},
       store = (() {
         // Every test owns a fresh in-memory database.
         driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
         return MatchStore(
           MatchDatabase(
             DatabaseConnection(
               NativeDatabase.memory(),
               closeStreamsSynchronously: true,
             ),
           ),
         );
       })();

  final List<gen.Match> _matches;
  final Map<String, List<RosterPlayer>> _rosters;
  final List<(String, List<RecordedEvent>, String)> _events = [];
  final List<void Function(MockBackend)> _pending = [];

  /// The device's offline store.
  final MatchStore store;

  /// The sync worker's timers.
  final timers = FakeTimers();

  MockBackend? _backend;

  /// The backend it was seeded into.
  MockBackend get backend => _backend!;

  MockGameApi get _game => backend.academyApis.game;

  static final matchesPath = RegExp(r'^/api/game/matches');
  static final eventsPath = RegExp(r'^/api/game/matches/[^/]+/events');
  static final feedPath = RegExp(r'^/api/game/matches/[^/]+/events$');
  static final boxScorePath = RegExp(r'^/api/game/matches/[^/]+/box-score$');
  static final rosterPath = RegExp(r'^/api/game/matches/[^/]+/roster$');
  static final sheetPath = RegExp(r'^/api/game/matches/[^/]+/box-score:pdf$');
  static final seasonStatsPath = RegExp(
    r'^/api/game/players/[^/]+/season-stats$',
  );

  /// A match seeded (or, before seeding, to seed); [roster] null: none.
  void addMatch(gen.Match match, {List<RosterPlayer>? roster}) {
    _matches.add(match);
    if (roster != null) _rosters[match.id] = roster;
    if (_backend != null) _seedMatch(match);
  }

  /// Sets the roster of [matchId].
  void setRoster(String matchId, List<RosterPlayer>? roster) {
    roster == null ? _rosters.remove(matchId) : _rosters[matchId] = roster;
    if (_backend != null) _game.seedRoster(matchId, _rosterJson(roster ?? []));
  }

  /// Events another scorer ([personId]) recorded, which reach the app
  /// through the feed (stored now when already seeded).
  void preload(
    String matchId,
    List<RecordedEvent> events, {
    String personId = 'other-scorer',
  }) => _backend == null
      ? _events.add((matchId, events, personId))
      : _seedEvents(matchId, events, personId);

  void seedInto(MockBackend backend) {
    _backend = backend;
    for (final m in _matches) {
      _seedMatch(m);
    }
    for (final (matchId, events, person) in _events) {
      _seedEvents(matchId, events, person);
    }
    for (final fault in _pending) {
      fault(backend);
    }
  }

  void _seedMatch(gen.Match m) {
    _game.seedMatch(
      (gen.standardSerializers.serialize(
                m,
                specifiedType: const FullType(gen.Match),
              )!
              as Map)
          .cast<String, Object?>(),
    );
    final roster = _rosters[m.id];
    if (roster != null) _game.seedRoster(m.id, _rosterJson(roster));
  }

  void _seedEvents(String matchId, List<RecordedEvent> events, String person) {
    for (final e in events) {
      _game.seedEvent(
        matchId,
        e.event.toJson(),
        person: person,
        serverSeq: e.serverSeq,
      );
    }
  }

  static List<Map<String, Object?>> _rosterJson(List<RosterPlayer> roster) => [
    for (final p in roster)
      {
        'playerId': p.playerId,
        'displayName': p.displayName,
        'jerseyNumber': p.jerseyNumber,
        'isStarter': p.isStarter,
      },
  ];

  void _fault(void Function(MockBackend) fault) =>
      _backend == null ? _pending.add(fault) : fault(_backend!);

  /// The events requests (batch and feed) fail like a dropped connection
  /// (true) or reach the mock again (false: heals every injected failure).
  set offline(bool value) => value
      ? _fault((b) => b.networkDown(eventsPath))
      : _fault((b) => b.heal());

  /// Answers the requests to [path] (every match path: null) with a
  /// Problem+JSON of [status], until [heal].
  void fail({Pattern? path, int status = 500, String? code}) =>
      _fault((b) => b.fail(path ?? matchesPath, status: status, code: code));

  /// The requests to [path] (every match path: null) fail like a dropped
  /// connection, until [heal].
  void networkDown([Pattern? path]) =>
      _fault((b) => b.networkDown(path ?? matchesPath));

  /// Holds every match request (the loading state).
  void hang() => _fault((b) => b.hang(matchesPath));

  /// Forgets the injected failures.
  void heal() {
    _pending.clear();
    _backend?.heal();
  }

  /// The events the service stored for [matchId].
  List<Map<String, Object?>> stored(String matchId) => _game.eventsOf(matchId);

  /// The match as the service keeps it (to change it as another device would).
  Map<String, Object?> serverMatch(String matchId) => _game.match(matchId)!;

  /// The requests the app sent to [path] with [method] (any: null).
  List<RequestOptions> requests(Pattern path, {String? method = 'GET'}) =>
      backend.requestsTo(path, method: method);

  /// How often the app pulled a feed.
  int get feedCalls => requests(feedPath).length;

  /// How often the app read a box score.
  int get boxScoreCalls => requests(boxScorePath).length;

  /// The device's store and the sync timers; the repository and the events
  /// remote are the app's own, on the backend.
  List<Override> get overrides => [
    matchStoreProvider.overrideWithValue(store),
    syncTimersProvider.overrideWithValue(timers),
  ];

  /// For tests of the providers without the app: the app's generated game
  /// client on the backend, in the backend's academy.
  List<Override> get apiOverrides => [
    gameApiProvider.overrideWithValue(
      gen.HoopsGameApi(dio: backend.dio(), interceptors: const []),
    ),
    tenantIdProvider.overrideWithValue(backend.tenantAId),
  ];
}
