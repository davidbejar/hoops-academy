import 'dart:convert';
import 'dart:io';

import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/projector/projection.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';

/// One server projection vector (`libs/contracts/vectors`, copied to
/// `test/fixtures/vectors` by `tool/sync_vectors.sh`).
class Vector {
  Vector(this.file, this.json);

  final String file;
  final Map<String, Object?> json;

  String get name => json['name']! as String;

  MatchRules get rules {
    final m = json['match']! as Map<String, Object?>;
    return MatchRules(
      periodCount: m['periodCount']! as int,
      periodMinutes: m['periodMinutes']! as int,
      overtimeMinutes: m['overtimeMinutes']! as int,
    );
  }

  List<RosterPlayer> get roster => [
    for (final r in (json['roster']! as List).cast<Map<String, Object?>>())
      RosterPlayer(
        playerId: r['playerId']! as String,
        displayName: r['displayName']! as String,
        jerseyNumber: r['jerseyNumber'] as String?,
        isStarter: r['isStarter']! as bool,
      ),
  ];

  List<Map<String, Object?>> get rawEvents =>
      (json['events']! as List).cast<Map<String, Object?>>();

  List<RecordedEvent> get events => [
    for (final e in rawEvents)
      RecordedEvent(
        MatchEvent.fromJson(e['event']! as Map<String, Object?>),
        serverSeq: e['serverSeq']! as int,
      ),
  ];

  Map<String, Object?> get expected =>
      json['expected']! as Map<String, Object?>;
}

const vectorsDir = 'test/fixtures/vectors';

List<Vector> loadVectors() {
  final files = Directory(vectorsDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      Vector(
        f.uri.pathSegments.last,
        jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
      ),
  ];
}

/// The projection in the vectors' `expected` shape (warning messages are not
/// part of the vectors).
Map<String, Object?> toVectorJson(Projection p) => {
  'playerStats': [
    for (final line in p.playerStats)
      {
        'playerId': line.playerId,
        'wasStarter': line.wasStarter,
        'stats': statsJson(line.stats),
        'warnings': [for (final w in line.warnings) warningJson(w)],
      },
  ],
  'summary': {
    'teamScore': p.summary.teamScore,
    'opponentScore': p.summary.opponentScore,
    'periodScores': [
      for (final s in p.summary.periodScores)
        {'period': s.period, 'team': s.team, 'opponent': s.opponent},
    ],
    'lastServerSeq': p.summary.lastServerSeq,
  },
  'teamTotals': statsJson(p.teamTotals),
  'warnings': [for (final w in p.warnings) warningJson(w)],
  'voidedBy': p.voidedBy,
};

Map<String, Object?> statsJson(StatLine s) => {
  'points': s.points,
  'fg1Made': s.fg1Made,
  'fg1Attempted': s.fg1Attempted,
  'fg2Made': s.fg2Made,
  'fg2Attempted': s.fg2Attempted,
  'fg3Made': s.fg3Made,
  'fg3Attempted': s.fg3Attempted,
  'assists': s.assists,
  'offensiveRebounds': s.offensiveRebounds,
  'defensiveRebounds': s.defensiveRebounds,
  'turnovers': s.turnovers,
  'steals': s.steals,
  'blocks': s.blocks,
  'personalFouls': s.personalFouls,
  'technicalFouls': s.technicalFouls,
  'unsportsmanlikeFouls': s.unsportsmanlikeFouls,
  'secondsPlayed': s.secondsPlayed,
};

Map<String, Object?> warningJson(ProjectionWarning w) => {
  'code': w.code,
  'eventId': w.eventId,
  'playerId': w.playerId,
};

/// Numbers compared numerically (a JSON `2` and `2.0` are the same value).
Object? normalise(Object? v) => switch (v) {
  num n => n.toDouble(),
  Map<String, Object?> m => {
    for (final e in m.entries) e.key: normalise(e.value),
  },
  List<Object?> l => [for (final x in l) normalise(x)],
  _ => v,
};
