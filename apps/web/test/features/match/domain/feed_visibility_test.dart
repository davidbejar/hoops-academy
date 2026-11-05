import 'package:flutter_test/flutter_test.dart' hide Timeout;
import 'package:hoops_app/features/match/domain/feed_visibility.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';

var _n = 0;
EventMeta meta() {
  _n++;
  return EventMeta(
    id: '0190b6a0-0000-7000-8000-${_n.toString().padLeft(12, '0')}',
    deviceId: 'd',
    clientSeq: _n,
    period: 1,
    clockSecondsRemaining: 500,
    recordedAtClient: DateTime.utc(2026, 11, 7, 10, 0, _n),
  );
}

void main() {
  test('null visible players (staff): every event', () {
    final events = [Shot(meta(), playerId: 'other', points: 2, made: true), SubOut(meta(), playerId: 'other')];
    expect(visibleFeed(events, (e) => e, visiblePlayers: null), events);
  });

  test('team-level events for everyone, player events of visible players only, VOIDs follow their target', () {
    final ownShot = Shot(meta(), playerId: 'own', points: 2, made: true);
    final otherShot = Shot(meta(), playerId: 'other', points: 3, made: true);
    final start = PeriodStart(meta());
    final opponent = OpponentScore(meta(), points: 2);
    final timeout = Timeout(meta(), side: TimeoutSide.own);
    final note = Note(meta(), text: 'Cold gym');
    final noteAboutOther = Note(meta(), playerId: 'other', text: 'Great D');
    final subIn = SubIn(meta(), playerId: 'other');
    final voidOwn = VoidEvent(meta(), target: ownShot.id);
    final voidOther = VoidEvent(meta(), target: otherShot.id);
    final voidOfVoidOther = VoidEvent(meta(), target: voidOther.id);
    final voidUnknown = VoidEvent(meta(), target: '0190b6a0-0000-7000-8000-999999999999');
    final all = <MatchEvent>[
      start, ownShot, otherShot, opponent, timeout, note, noteAboutOther, subIn,
      voidOwn, voidOther, voidOfVoidOther, voidUnknown,
    ];

    expect(visibleFeed(all, (e) => e, visiblePlayers: {'own'}), [start, ownShot, opponent, timeout, note, voidOwn, voidUnknown]);
    expect(visibleFeed(all, (e) => e, visiblePlayers: {}), [start, opponent, timeout, note, voidUnknown]);
  });
}
