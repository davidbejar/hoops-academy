// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Match extends Match {
  @override
  final String id;
  @override
  final String teamId;
  @override
  final String seasonId;
  @override
  final String opponentName;
  @override
  final HomeAway homeAway;
  @override
  final DateTime scheduledAt;
  @override
  final String? venue;
  @override
  final MatchStatus status;
  @override
  final int periodCount;
  @override
  final int periodMinutes;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? finishedAt;
  @override
  final DateTime? cancelledAt;
  @override
  final String? cancelReason;
  @override
  final Score score;
  @override
  final int lastServerSeq;

  factory _$Match([void Function(MatchBuilder)? updates]) =>
      (MatchBuilder()..update(updates))._build();

  _$Match._(
      {required this.id,
      required this.teamId,
      required this.seasonId,
      required this.opponentName,
      required this.homeAway,
      required this.scheduledAt,
      this.venue,
      required this.status,
      required this.periodCount,
      required this.periodMinutes,
      this.startedAt,
      this.finishedAt,
      this.cancelledAt,
      this.cancelReason,
      required this.score,
      required this.lastServerSeq})
      : super._();
  @override
  Match rebuild(void Function(MatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchBuilder toBuilder() => MatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Match &&
        id == other.id &&
        teamId == other.teamId &&
        seasonId == other.seasonId &&
        opponentName == other.opponentName &&
        homeAway == other.homeAway &&
        scheduledAt == other.scheduledAt &&
        venue == other.venue &&
        status == other.status &&
        periodCount == other.periodCount &&
        periodMinutes == other.periodMinutes &&
        startedAt == other.startedAt &&
        finishedAt == other.finishedAt &&
        cancelledAt == other.cancelledAt &&
        cancelReason == other.cancelReason &&
        score == other.score &&
        lastServerSeq == other.lastServerSeq;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, opponentName.hashCode);
    _$hash = $jc(_$hash, homeAway.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, venue.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, periodCount.hashCode);
    _$hash = $jc(_$hash, periodMinutes.hashCode);
    _$hash = $jc(_$hash, startedAt.hashCode);
    _$hash = $jc(_$hash, finishedAt.hashCode);
    _$hash = $jc(_$hash, cancelledAt.hashCode);
    _$hash = $jc(_$hash, cancelReason.hashCode);
    _$hash = $jc(_$hash, score.hashCode);
    _$hash = $jc(_$hash, lastServerSeq.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Match')
          ..add('id', id)
          ..add('teamId', teamId)
          ..add('seasonId', seasonId)
          ..add('opponentName', opponentName)
          ..add('homeAway', homeAway)
          ..add('scheduledAt', scheduledAt)
          ..add('venue', venue)
          ..add('status', status)
          ..add('periodCount', periodCount)
          ..add('periodMinutes', periodMinutes)
          ..add('startedAt', startedAt)
          ..add('finishedAt', finishedAt)
          ..add('cancelledAt', cancelledAt)
          ..add('cancelReason', cancelReason)
          ..add('score', score)
          ..add('lastServerSeq', lastServerSeq))
        .toString();
  }
}

class MatchBuilder implements Builder<Match, MatchBuilder> {
  _$Match? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

  String? _opponentName;
  String? get opponentName => _$this._opponentName;
  set opponentName(String? opponentName) => _$this._opponentName = opponentName;

  HomeAway? _homeAway;
  HomeAway? get homeAway => _$this._homeAway;
  set homeAway(HomeAway? homeAway) => _$this._homeAway = homeAway;

  DateTime? _scheduledAt;
  DateTime? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(DateTime? scheduledAt) => _$this._scheduledAt = scheduledAt;

  String? _venue;
  String? get venue => _$this._venue;
  set venue(String? venue) => _$this._venue = venue;

  MatchStatus? _status;
  MatchStatus? get status => _$this._status;
  set status(MatchStatus? status) => _$this._status = status;

  int? _periodCount;
  int? get periodCount => _$this._periodCount;
  set periodCount(int? periodCount) => _$this._periodCount = periodCount;

  int? _periodMinutes;
  int? get periodMinutes => _$this._periodMinutes;
  set periodMinutes(int? periodMinutes) =>
      _$this._periodMinutes = periodMinutes;

  DateTime? _startedAt;
  DateTime? get startedAt => _$this._startedAt;
  set startedAt(DateTime? startedAt) => _$this._startedAt = startedAt;

  DateTime? _finishedAt;
  DateTime? get finishedAt => _$this._finishedAt;
  set finishedAt(DateTime? finishedAt) => _$this._finishedAt = finishedAt;

  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _$this._cancelledAt;
  set cancelledAt(DateTime? cancelledAt) => _$this._cancelledAt = cancelledAt;

  String? _cancelReason;
  String? get cancelReason => _$this._cancelReason;
  set cancelReason(String? cancelReason) => _$this._cancelReason = cancelReason;

  ScoreBuilder? _score;
  ScoreBuilder get score => _$this._score ??= ScoreBuilder();
  set score(ScoreBuilder? score) => _$this._score = score;

  int? _lastServerSeq;
  int? get lastServerSeq => _$this._lastServerSeq;
  set lastServerSeq(int? lastServerSeq) =>
      _$this._lastServerSeq = lastServerSeq;

  MatchBuilder() {
    Match._defaults(this);
  }

  MatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _teamId = $v.teamId;
      _seasonId = $v.seasonId;
      _opponentName = $v.opponentName;
      _homeAway = $v.homeAway;
      _scheduledAt = $v.scheduledAt;
      _venue = $v.venue;
      _status = $v.status;
      _periodCount = $v.periodCount;
      _periodMinutes = $v.periodMinutes;
      _startedAt = $v.startedAt;
      _finishedAt = $v.finishedAt;
      _cancelledAt = $v.cancelledAt;
      _cancelReason = $v.cancelReason;
      _score = $v.score.toBuilder();
      _lastServerSeq = $v.lastServerSeq;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Match other) {
    _$v = other as _$Match;
  }

  @override
  void update(void Function(MatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Match build() => _build();

  _$Match _build() {
    _$Match _$result;
    try {
      _$result = _$v ??
          _$Match._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Match', 'id'),
            teamId: BuiltValueNullFieldError.checkNotNull(
                teamId, r'Match', 'teamId'),
            seasonId: BuiltValueNullFieldError.checkNotNull(
                seasonId, r'Match', 'seasonId'),
            opponentName: BuiltValueNullFieldError.checkNotNull(
                opponentName, r'Match', 'opponentName'),
            homeAway: BuiltValueNullFieldError.checkNotNull(
                homeAway, r'Match', 'homeAway'),
            scheduledAt: BuiltValueNullFieldError.checkNotNull(
                scheduledAt, r'Match', 'scheduledAt'),
            venue: venue,
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'Match', 'status'),
            periodCount: BuiltValueNullFieldError.checkNotNull(
                periodCount, r'Match', 'periodCount'),
            periodMinutes: BuiltValueNullFieldError.checkNotNull(
                periodMinutes, r'Match', 'periodMinutes'),
            startedAt: startedAt,
            finishedAt: finishedAt,
            cancelledAt: cancelledAt,
            cancelReason: cancelReason,
            score: score.build(),
            lastServerSeq: BuiltValueNullFieldError.checkNotNull(
                lastServerSeq, r'Match', 'lastServerSeq'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'score';
        score.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Match', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
