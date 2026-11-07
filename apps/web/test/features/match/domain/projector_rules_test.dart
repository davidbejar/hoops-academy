import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/projector/projection.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';

const _rules = MatchRules(periodCount: 4, periodMinutes: 10);
const _roster = [
  RosterPlayer(playerId: 'ana', displayName: 'Ana', isStarter: true),
  RosterPlayer(playerId: 'bo', displayName: 'Bo', isStarter: false),
];

var _n = 0;
EventMeta _meta({int period = 1, int clock = 600}) {
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

RecordedEvent _local(MatchEvent e) => RecordedEvent(e);

int _seconds(Projection p, String player) =>
    p.lineOf(player)!.stats.secondsPlayed;

/// Projection rules the server vectors leave open (WP88: pinned for the
/// Dart mutation run).
void main() {
  test('overtimes last five minutes unless the rules say otherwise', () {
    expect(_rules.overtimeMinutes, 5);
    expect(_rules.periodSeconds(4), 600);
    expect(_rules.periodSeconds(5), 300);
    expect(MatchRules.playersOnCourt, 5);
  });

  test('before any event nothing runs and nothing was synced', () {
    final p = project(_rules, _roster, const []);
    expect(p.live.period, 0);
    expect(p.live.clock, 0);
    expect(p.live.running, isFalse);
    expect(p.summary.lastServerSeq, 0);
  });

  test('lastServerSeq is the highest synced one; local events count 0', () {
    final local = project(_rules, _roster, [
      _local(PeriodStart(_meta())),
      _local(Shot(_meta(clock: 590), playerId: 'ana', points: 2, made: true)),
    ]);
    expect(local.summary.lastServerSeq, 0);
    final mixed = project(_rules, _roster, [
      RecordedEvent(PeriodStart(_meta()), serverSeq: 7),
      RecordedEvent(SubIn(_meta(clock: 590), playerId: 'bo'), serverSeq: 3),
      _local(SubOut(_meta(clock: 580), playerId: 'bo')),
    ]);
    expect(mixed.summary.lastServerSeq, 7);
  });

  test('a player in and out at the same clock played no second', () {
    final p = project(_rules, _roster, [
      _local(PeriodStart(_meta())),
      _local(SubIn(_meta(clock: 500), playerId: 'bo')),
      _local(SubOut(_meta(clock: 500), playerId: 'bo')),
      _local(PeriodEnd(_meta(clock: 0))),
    ]);
    expect(_seconds(p, 'bo'), 0);
    expect(_seconds(p, 'ana'), 600);
  });

  test('a match that ends inside a period counts the time to the last '
      'event', () {
    final p = project(_rules, _roster, [
      _local(PeriodStart(_meta())),
      _local(SubIn(_meta(clock: 550), playerId: 'bo')),
      _local(Shot(_meta(clock: 500), playerId: 'ana', points: 2, made: true)),
    ]);
    expect(p.live.running, isTrue);
    expect(p.live.clock, 500);
    expect(_seconds(p, 'ana'), 100);
    expect(_seconds(p, 'bo'), 50);
  });

  test('from the bench only a technical or unsportsmanlike foul counts '
      'without a warning', () {
    final technical = Foul(
      _meta(clock: 590),
      playerId: 'bo',
      kind: FoulKind.technical,
    );
    final unsportsmanlike = Foul(
      _meta(clock: 585),
      playerId: 'bo',
      kind: FoulKind.unsportsmanlike,
    );
    final personal = Foul(
      _meta(clock: 580),
      playerId: 'bo',
      kind: FoulKind.personal,
    );
    final p = project(_rules, _roster, [
      _local(PeriodStart(_meta())),
      _local(technical),
      _local(unsportsmanlike),
      _local(personal),
    ]);
    final warnings = p.lineOf('bo')!.warnings;
    expect(warnings.map((w) => (w.code, w.eventId)), [
      (WarningCode.playerNotOnCourt, personal.id),
    ]);
  });
}
