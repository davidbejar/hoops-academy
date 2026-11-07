import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/projector/projection.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';
import 'package:hoops_app/features/match/domain/projector/team_figures.dart';

const rules = MatchRules(periodCount: 4, periodMinutes: 10);
const roster = [
  RosterPlayer(playerId: 'own', displayName: 'Own', isStarter: true),
  RosterPlayer(playerId: 'other', displayName: 'Other', isStarter: true),
];

var _n = 0;
EventMeta meta({int period = 1, int clock = 500}) {
  _n++;
  return EventMeta(
    id: '0190b6a0-0000-7000-8000-${_n.toString().padLeft(12, '0')}',
    deviceId: 'd',
    clientSeq: _n,
    period: period,
    clockSecondsRemaining: clock,
    recordedAtClient: DateTime.utc(2026, 11, 7, 10, 0, _n),
  );
}

/// The server's box score at serverSeq 5: 10–8, all of it in period 1.
const official = OfficialFigures(
  lastServerSeq: 5,
  figures: TeamFigures(
    teamScore: 10,
    opponentScore: 8,
    periodScores: [PeriodScore(1, 10, 8)],
    teamTotals: StatLine(points: 10, fg2Made: 5, fg2Attempted: 7),
  ),
);

void main() {
  test('staff: the figures are the local projection', () {
    final events = [
      RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
      RecordedEvent(
        Shot(meta(), playerId: 'other', points: 3, made: true),
        serverSeq: 2,
      ),
      RecordedEvent(OpponentScore(meta(), points: 2), serverSeq: 3),
    ];
    final f = TeamFigures.of(project(rules, roster, events));
    expect([f.teamScore, f.opponentScore], [3, 2]);
    expect(f.periodScores!.first.team, 3);
    expect(f.teamTotals!.fg3Made, 1);
  });

  test('visible events the snapshot already counts are not added again', () {
    final events = [
      RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
      RecordedEvent(
        Shot(meta(), playerId: 'own', points: 2, made: true),
        serverSeq: 4,
      ),
    ];
    final f = reconcileTeamFigures(
      official: official,
      rules: rules,
      roster: roster,
      events: events,
    );
    expect([f.teamScore, f.opponentScore], [10, 8]);
    expect(f.periodScores!.map((p) => [p.period, p.team, p.opponent]), [
      [1, 10, 8],
      [2, 0, 0],
      [3, 0, 0],
      [4, 0, 0],
    ]);
    expect(f.teamTotals!.points, 10);
  });

  test('own unsynced events and newer visible events are added to the snapshot, per period', () {
    final events = [
      RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
      RecordedEvent(PeriodEnd(meta(clock: 0)), serverSeq: 5),
      RecordedEvent(PeriodStart(meta(period: 2, clock: 600)), serverSeq: 9),
      RecordedEvent(
        Shot(meta(period: 2), playerId: 'own', points: 3, made: true),
      ), // not synced yet
      RecordedEvent(
        OpponentScore(meta(period: 2, clock: 400), points: 2),
        serverSeq: 12,
      ),
    ];
    final f = reconcileTeamFigures(
      official: official,
      rules: rules,
      roster: roster,
      events: events,
    );
    expect([f.teamScore, f.opponentScore], [13, 10]);
    expect(f.periodScores!.map((p) => [p.period, p.team, p.opponent]), [
      [1, 10, 8],
      [2, 3, 2],
      [3, 0, 0],
      [4, 0, 0],
    ]);
    expect(f.teamTotals!.points, 13);
    expect(f.teamTotals!.fg3Made, 1);
    expect(f.teamTotals!.fg2Made, 5);
  });

  test('a VOID after the snapshot takes back what the snapshot counted', () {
    final shot = Shot(meta(), playerId: 'own', points: 2, made: true);
    final events = [
      RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
      RecordedEvent(shot, serverSeq: 3),
      RecordedEvent(VoidEvent(meta(clock: 450), target: shot.id)),
    ];
    final f = reconcileTeamFigures(
      official: official,
      rules: rules,
      roster: roster,
      events: events,
    );
    expect(f.teamScore, 8);
    expect(f.periodScores!.first.team, 8);
    expect(f.teamTotals!.fg2Made, 4);
  });

  test(
    'a snapshot with the score only keeps period scores and totals unknown',
    () {
      const scoreOnly = OfficialFigures(
        lastServerSeq: 5,
        figures: TeamFigures(teamScore: 10, opponentScore: 8),
      );
      final events = [
        RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
        RecordedEvent(Shot(meta(), playerId: 'own', points: 1, made: true)),
      ];
      final f = reconcileTeamFigures(
        official: scoreOnly,
        rules: rules,
        roster: roster,
        events: events,
      );
      expect([f.teamScore, f.opponentScore], [11, 8]);
      expect(f.periodScores, isNull);
      expect(f.teamTotals, isNull);
    },
  );

  test('an event stored exactly at the snapshot is already counted', () {
    final f = reconcileTeamFigures(
      official: official,
      rules: rules,
      roster: roster,
      events: [
        RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
        RecordedEvent(
          Shot(meta(), playerId: 'own', points: 2, made: true),
          serverSeq: 5,
        ),
      ],
    );
    expect(f.teamScore, 10);
  });

  test('a snapshot that does not hold what a later VOID takes back never '
      'goes below zero', () {
    const empty = OfficialFigures(
      lastServerSeq: 5,
      figures: TeamFigures(
        teamScore: 0,
        opponentScore: 0,
        periodScores: [PeriodScore(1, 0, 0)],
      ),
    );
    final shot = Shot(meta(), playerId: 'own', points: 2, made: true);
    final theirs = OpponentScore(meta(clock: 480), points: 3);
    final f = reconcileTeamFigures(
      official: empty,
      rules: rules,
      roster: roster,
      events: [
        RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1),
        RecordedEvent(shot, serverSeq: 3),
        RecordedEvent(theirs, serverSeq: 4),
        RecordedEvent(VoidEvent(meta(clock: 450), target: shot.id)),
        RecordedEvent(VoidEvent(meta(clock: 440), target: theirs.id)),
      ],
    );
    expect([f.teamScore, f.opponentScore], [0, 0]);
    expect(f.periodScores!.first.team, 0);
    expect(f.periodScores!.first.opponent, 0);
  });

  test('nothing new on a 0-0 snapshot stays 0-0', () {
    const empty = OfficialFigures(
      lastServerSeq: 1,
      figures: TeamFigures(
        teamScore: 0,
        opponentScore: 0,
        periodScores: [PeriodScore(1, 0, 0)],
      ),
    );
    final f = reconcileTeamFigures(
      official: empty,
      rules: rules,
      roster: roster,
      events: [RecordedEvent(PeriodStart(meta(clock: 600)), serverSeq: 1)],
    );
    expect([f.teamScore, f.opponentScore], [0, 0]);
    expect(f.periodScores!.first.team, 0);
    expect(f.periodScores!.first.opponent, 0);
  });
}
