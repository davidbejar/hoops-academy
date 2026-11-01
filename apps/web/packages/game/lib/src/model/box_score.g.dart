// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_score.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BoxScore extends BoxScore {
  @override
  final String matchId;
  @override
  final MatchStatus status;
  @override
  final Score score;
  @override
  final BuiltList<PeriodScore> periodScores;
  @override
  final StatLine teamTotals;
  @override
  final BuiltList<PlayerMatchStats> players;
  @override
  final BuiltList<ProjectionWarning> warnings;
  @override
  final int lastServerSeq;

  factory _$BoxScore([void Function(BoxScoreBuilder)? updates]) =>
      (BoxScoreBuilder()..update(updates))._build();

  _$BoxScore._(
      {required this.matchId,
      required this.status,
      required this.score,
      required this.periodScores,
      required this.teamTotals,
      required this.players,
      required this.warnings,
      required this.lastServerSeq})
      : super._();
  @override
  BoxScore rebuild(void Function(BoxScoreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BoxScoreBuilder toBuilder() => BoxScoreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BoxScore &&
        matchId == other.matchId &&
        status == other.status &&
        score == other.score &&
        periodScores == other.periodScores &&
        teamTotals == other.teamTotals &&
        players == other.players &&
        warnings == other.warnings &&
        lastServerSeq == other.lastServerSeq;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, matchId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, score.hashCode);
    _$hash = $jc(_$hash, periodScores.hashCode);
    _$hash = $jc(_$hash, teamTotals.hashCode);
    _$hash = $jc(_$hash, players.hashCode);
    _$hash = $jc(_$hash, warnings.hashCode);
    _$hash = $jc(_$hash, lastServerSeq.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BoxScore')
          ..add('matchId', matchId)
          ..add('status', status)
          ..add('score', score)
          ..add('periodScores', periodScores)
          ..add('teamTotals', teamTotals)
          ..add('players', players)
          ..add('warnings', warnings)
          ..add('lastServerSeq', lastServerSeq))
        .toString();
  }
}

class BoxScoreBuilder implements Builder<BoxScore, BoxScoreBuilder> {
  _$BoxScore? _$v;

  String? _matchId;
  String? get matchId => _$this._matchId;
  set matchId(String? matchId) => _$this._matchId = matchId;

  MatchStatus? _status;
  MatchStatus? get status => _$this._status;
  set status(MatchStatus? status) => _$this._status = status;

  ScoreBuilder? _score;
  ScoreBuilder get score => _$this._score ??= ScoreBuilder();
  set score(ScoreBuilder? score) => _$this._score = score;

  ListBuilder<PeriodScore>? _periodScores;
  ListBuilder<PeriodScore> get periodScores =>
      _$this._periodScores ??= ListBuilder<PeriodScore>();
  set periodScores(ListBuilder<PeriodScore>? periodScores) =>
      _$this._periodScores = periodScores;

  StatLineBuilder? _teamTotals;
  StatLineBuilder get teamTotals => _$this._teamTotals ??= StatLineBuilder();
  set teamTotals(StatLineBuilder? teamTotals) =>
      _$this._teamTotals = teamTotals;

  ListBuilder<PlayerMatchStats>? _players;
  ListBuilder<PlayerMatchStats> get players =>
      _$this._players ??= ListBuilder<PlayerMatchStats>();
  set players(ListBuilder<PlayerMatchStats>? players) =>
      _$this._players = players;

  ListBuilder<ProjectionWarning>? _warnings;
  ListBuilder<ProjectionWarning> get warnings =>
      _$this._warnings ??= ListBuilder<ProjectionWarning>();
  set warnings(ListBuilder<ProjectionWarning>? warnings) =>
      _$this._warnings = warnings;

  int? _lastServerSeq;
  int? get lastServerSeq => _$this._lastServerSeq;
  set lastServerSeq(int? lastServerSeq) =>
      _$this._lastServerSeq = lastServerSeq;

  BoxScoreBuilder() {
    BoxScore._defaults(this);
  }

  BoxScoreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _matchId = $v.matchId;
      _status = $v.status;
      _score = $v.score.toBuilder();
      _periodScores = $v.periodScores.toBuilder();
      _teamTotals = $v.teamTotals.toBuilder();
      _players = $v.players.toBuilder();
      _warnings = $v.warnings.toBuilder();
      _lastServerSeq = $v.lastServerSeq;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BoxScore other) {
    _$v = other as _$BoxScore;
  }

  @override
  void update(void Function(BoxScoreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BoxScore build() => _build();

  _$BoxScore _build() {
    _$BoxScore _$result;
    try {
      _$result = _$v ??
          _$BoxScore._(
            matchId: BuiltValueNullFieldError.checkNotNull(
                matchId, r'BoxScore', 'matchId'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'BoxScore', 'status'),
            score: score.build(),
            periodScores: periodScores.build(),
            teamTotals: teamTotals.build(),
            players: players.build(),
            warnings: warnings.build(),
            lastServerSeq: BuiltValueNullFieldError.checkNotNull(
                lastServerSeq, r'BoxScore', 'lastServerSeq'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'score';
        score.build();
        _$failedField = 'periodScores';
        periodScores.build();
        _$failedField = 'teamTotals';
        teamTotals.build();
        _$failedField = 'players';
        players.build();
        _$failedField = 'warnings';
        warnings.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BoxScore', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
