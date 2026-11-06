/// Pure box-score projection, mirroring game-service `BoxScoreProjector`
/// (ADR-0014, `libs/contracts/vectors/README.md`). The result depends only
/// on the SET of events: arrival order and duplicates are irrelevant.
library;

import 'dart:math' as math;

import '../match_event.dart';
import 'event_ordering.dart';
import 'projection.dart';

/// Timing rules. Periods above [periodCount] are overtimes of [overtimeMinutes].
class MatchRules {
  const MatchRules({
    required this.periodCount,
    required this.periodMinutes,
    this.overtimeMinutes = defaultOvertimeMinutes,
  });

  static const defaultOvertimeMinutes = 5;
  static const playersOnCourt = 5;

  final int periodCount;
  final int periodMinutes;
  final int overtimeMinutes;

  int periodSeconds(int period) =>
      60 * (period <= periodCount ? periodMinutes : overtimeMinutes);
}

/// One match-roster player (line order = roster order).
class RosterPlayer {
  const RosterPlayer({
    required this.playerId,
    required this.displayName,
    this.jerseyNumber,
    required this.isStarter,
  });
  final String playerId;
  final String displayName;
  final String? jerseyNumber;
  final bool isStarter;
}

Projection project(
  MatchRules rules,
  List<RosterPlayer> roster,
  Iterable<RecordedEvent> events,
) {
  final gameOrder = canonicalOrder(events);
  final voids = _VoidResolution.resolve(gameOrder);
  final run = _Run(rules, roster);
  for (final e in gameOrder) {
    if (!voids.excludes(e)) run.apply(e.event);
  }
  final lastServerSeq = gameOrder.fold<int>(
    0,
    (m, e) => math.max(m, e.serverSeq ?? 0),
  );
  return run.finish(lastServerSeq, voids);
}

class _VoidResolution {
  _VoidResolution(this.voidedBy, this.warnings);
  final Map<String, String> voidedBy;
  final List<ProjectionWarning> warnings;

  static _VoidResolution resolve(List<RecordedEvent> gameOrder) {
    final byId = {for (final e in gameOrder) e.id: e.event};
    final voidedBy = <String, String>{};
    final warnings = <ProjectionWarning>[];
    for (final r in gameOrder) {
      final v = r.event;
      if (v is! VoidEvent) continue;
      final target = byId[v.target];
      if (target == null) {
        warnings.add(
          ProjectionWarning(
            code: WarningCode.voidTargetNotFound,
            eventId: v.id,
          ),
        );
      } else if (target is VoidEvent) {
        warnings.add(
          ProjectionWarning(code: WarningCode.voidOfVoid, eventId: v.id),
        );
      } else {
        voidedBy.putIfAbsent(v.target, () => v.id);
      }
    }
    return _VoidResolution(voidedBy, warnings);
  }

  bool excludes(RecordedEvent r) =>
      r.event is VoidEvent || voidedBy.containsKey(r.id);
}

class _Tally {
  _Tally(this.playerId, this.starter) : onCourt = starter;

  final String playerId;
  final bool starter;
  final warnings = <ProjectionWarning>[];
  bool onCourt;
  int _enteredAt = 0;
  int seconds = 0;
  int fg1m = 0, fg1a = 0, fg2m = 0, fg2a = 0, fg3m = 0, fg3a = 0;
  int ast = 0, oreb = 0, dreb = 0, tov = 0, stl = 0, blk = 0;
  int fouls = 0, tech = 0, unsport = 0;

  void enter(int clock) {
    onCourt = true;
    _enteredAt = clock;
  }

  void resumeAt(int clock) => _enteredAt = clock;

  void accrueUntil(int clock) {
    seconds += math.max(0, _enteredAt - clock);
    _enteredAt = clock;
  }

  void record(PlayerStat stat) {
    switch (stat) {
      case Shot(:final points, :final made):
        final m = made ? 1 : 0;
        switch (points) {
          case 1:
            fg1a++;
            fg1m += m;
          case 2:
            fg2a++;
            fg2m += m;
          default:
            fg3a++;
            fg3m += m;
        }
      case Assist():
        ast++;
      case Rebound(:final kind):
        kind == ReboundKind.offensive ? oreb++ : dreb++;
      case Turnover():
        tov++;
      case Steal():
        stl++;
      case Block():
        blk++;
      case Foul(:final kind):
        fouls++;
        if (kind == FoulKind.technical) tech++;
        if (kind == FoulKind.unsportsmanlike) unsport++;
    }
  }

  PlayerLine toLine() => PlayerLine(
    playerId: playerId,
    wasStarter: starter,
    warnings: List.unmodifiable(warnings),
    stats: StatLine(
      points: fg1m + 2 * fg2m + 3 * fg3m,
      fg1Made: fg1m,
      fg1Attempted: fg1a,
      fg2Made: fg2m,
      fg2Attempted: fg2a,
      fg3Made: fg3m,
      fg3Attempted: fg3a,
      assists: ast,
      offensiveRebounds: oreb,
      defensiveRebounds: dreb,
      turnovers: tov,
      steals: stl,
      blocks: blk,
      personalFouls: fouls,
      technicalFouls: tech,
      unsportsmanlikeFouls: unsport,
      secondsPlayed: seconds,
    ),
  );
}

/// One replay in game order. Starters are on court before the first period;
/// the clock runs only between PERIOD_START and PERIOD_END.
class _Run {
  _Run(this.rules, List<RosterPlayer> roster)
    : _lastPeriodSeen = rules.periodCount {
    for (final r in roster) {
      _tallies[r.playerId] = _Tally(r.playerId, r.isStarter);
    }
  }

  final MatchRules rules;
  final _tallies = <String, _Tally>{};
  final _matchWarnings = <ProjectionWarning>[];
  final _byPeriod = <int, List<int>>{};
  final _played = <int>{};
  int _currentPeriod = 0;
  bool _running = false;
  int _lastClock = 0;
  int _lastPeriodSeen;

  Iterable<_Tally> get _onCourt => _tallies.values.where((t) => t.onCourt);

  void apply(MatchEvent event) {
    final period = event.meta.period;
    final clock = _clamped(event);
    _lastPeriodSeen = math.max(_lastPeriodSeen, period);
    if (_running && period != _currentPeriod) {
      _warn(WarningCode.missingPeriodEnd, event);
      _closePeriod(0);
    }
    switch (event) {
      case PeriodStart():
        _start(event, clock);
      case PeriodEnd():
        _running
            ? _closePeriod(clock)
            : _warn(WarningCode.periodNotRunning, event);
      case SubIn():
        _subIn(event, clock);
      case SubOut():
        _subOut(event, clock);
      case PlayerStat():
        _stat(event);
      case OpponentScore(:final points):
        if (!_running) _warn(WarningCode.eventOutsidePeriod, event);
        _score(period, opponent: points);
      case Timeout() || Note() || VoidEvent():
        break;
    }
    if (_running) _lastClock = clock;
  }

  int _clamped(MatchEvent event) {
    final length = rules.periodSeconds(event.meta.period);
    final clock = event.meta.clockSecondsRemaining;
    if (clock > length) {
      _warn(WarningCode.clockOutOfRange, event);
      return length;
    }
    return clock;
  }

  void _start(PeriodStart start, int clock) {
    final period = start.meta.period;
    if (_running) {
      _warn(WarningCode.periodAlreadyRunning, start);
    } else if (_played.contains(period)) {
      _warn(WarningCode.periodAlreadyPlayed, start);
    } else {
      _running = true;
      _currentPeriod = period;
      _played.add(period);
      for (final t in _onCourt) {
        t.resumeAt(clock);
      }
    }
  }

  void _closePeriod(int clock) {
    for (final t in _onCourt) {
      t.accrueUntil(clock);
    }
    _running = false;
  }

  void _subIn(SubIn e, int clock) {
    final t = _rosterPlayer(e, e.player);
    if (t == null) return;
    if (t.onCourt) {
      t.warnings.add(
        ProjectionWarning(
          code: WarningCode.subInPlayerOnCourt,
          eventId: e.id,
          playerId: e.player,
        ),
      );
      return;
    }
    t.enter(clock);
    if (_onCourt.length > MatchRules.playersOnCourt)
      _warn(WarningCode.tooManyPlayersOnCourt, e);
  }

  void _subOut(SubOut e, int clock) {
    final t = _rosterPlayer(e, e.player);
    if (t == null) return;
    if (!t.onCourt) {
      t.warnings.add(
        ProjectionWarning(
          code: WarningCode.subOutPlayerNotOnCourt,
          eventId: e.id,
          playerId: e.player,
        ),
      );
      return;
    }
    if (_running) t.accrueUntil(clock);
    t.onCourt = false;
  }

  void _stat(PlayerStat stat) {
    if (stat is Shot && stat.made) _score(stat.meta.period, team: stat.points);
    final t = _rosterPlayer(stat, stat.player);
    if (t == null) return;
    if (!_running) {
      t.warnings.add(
        ProjectionWarning(
          code: WarningCode.eventOutsidePeriod,
          eventId: stat.id,
          playerId: stat.player,
        ),
      );
    } else if (!t.onCourt && !_allowedFromBench(stat)) {
      t.warnings.add(
        ProjectionWarning(
          code: WarningCode.playerNotOnCourt,
          eventId: stat.id,
          playerId: stat.player,
        ),
      );
    }
    t.record(stat);
  }

  static bool _allowedFromBench(PlayerStat s) =>
      s is Foul && s.kind != FoulKind.personal;

  void _score(int period, {int team = 0, int opponent = 0}) {
    final p = _byPeriod.putIfAbsent(period, () => [0, 0]);
    p[0] += team;
    p[1] += opponent;
  }

  _Tally? _rosterPlayer(MatchEvent event, String player) {
    final t = _tallies[player];
    if (t == null) _warn(WarningCode.playerNotInRoster, event, player: player);
    return t;
  }

  void _warn(String code, MatchEvent event, {String? player}) => _matchWarnings
      .add(ProjectionWarning(code: code, eventId: event.id, playerId: player));

  Projection finish(int lastServerSeq, _VoidResolution voids) {
    if (_running) {
      for (final t in _onCourt) {
        t.accrueUntil(_lastClock);
      }
    }
    final periods = <PeriodScore>[];
    var team = 0, opponent = 0;
    for (var p = 1; p <= _lastPeriodSeen; p++) {
      final s = _byPeriod[p] ?? const [0, 0];
      periods.add(PeriodScore(p, s[0], s[1]));
      team += s[0];
      opponent += s[1];
    }
    return Projection(
      playerStats: [for (final t in _tallies.values) t.toLine()],
      summary: MatchSummary(
        teamScore: team,
        opponentScore: opponent,
        periodScores: periods,
        lastServerSeq: lastServerSeq,
      ),
      warnings: [...voids.warnings, ..._matchWarnings],
      voidedBy: Map.unmodifiable(voids.voidedBy),
      live: LiveState(
        onCourt: {for (final t in _onCourt) t.playerId},
        period: _currentPeriod,
        running: _running,
        clock: _lastClock,
        playedPeriods: Set.unmodifiable(_played),
      ),
    );
  }
}
