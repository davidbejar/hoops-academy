// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_match_line.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerMatchLine extends PlayerMatchLine {
  @override
  final String matchId;
  @override
  final DateTime scheduledAt;
  @override
  final String opponentName;
  @override
  final MatchStatus status;
  @override
  final bool wasStarter;
  @override
  final StatLine stats;

  factory _$PlayerMatchLine([void Function(PlayerMatchLineBuilder)? updates]) =>
      (PlayerMatchLineBuilder()..update(updates))._build();

  _$PlayerMatchLine._(
      {required this.matchId,
      required this.scheduledAt,
      required this.opponentName,
      required this.status,
      required this.wasStarter,
      required this.stats})
      : super._();
  @override
  PlayerMatchLine rebuild(void Function(PlayerMatchLineBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerMatchLineBuilder toBuilder() => PlayerMatchLineBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerMatchLine &&
        matchId == other.matchId &&
        scheduledAt == other.scheduledAt &&
        opponentName == other.opponentName &&
        status == other.status &&
        wasStarter == other.wasStarter &&
        stats == other.stats;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, matchId.hashCode);
    _$hash = $jc(_$hash, scheduledAt.hashCode);
    _$hash = $jc(_$hash, opponentName.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, wasStarter.hashCode);
    _$hash = $jc(_$hash, stats.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerMatchLine')
          ..add('matchId', matchId)
          ..add('scheduledAt', scheduledAt)
          ..add('opponentName', opponentName)
          ..add('status', status)
          ..add('wasStarter', wasStarter)
          ..add('stats', stats))
        .toString();
  }
}

class PlayerMatchLineBuilder
    implements Builder<PlayerMatchLine, PlayerMatchLineBuilder> {
  _$PlayerMatchLine? _$v;

  String? _matchId;
  String? get matchId => _$this._matchId;
  set matchId(String? matchId) => _$this._matchId = matchId;

  DateTime? _scheduledAt;
  DateTime? get scheduledAt => _$this._scheduledAt;
  set scheduledAt(DateTime? scheduledAt) => _$this._scheduledAt = scheduledAt;

  String? _opponentName;
  String? get opponentName => _$this._opponentName;
  set opponentName(String? opponentName) => _$this._opponentName = opponentName;

  MatchStatus? _status;
  MatchStatus? get status => _$this._status;
  set status(MatchStatus? status) => _$this._status = status;

  bool? _wasStarter;
  bool? get wasStarter => _$this._wasStarter;
  set wasStarter(bool? wasStarter) => _$this._wasStarter = wasStarter;

  StatLineBuilder? _stats;
  StatLineBuilder get stats => _$this._stats ??= StatLineBuilder();
  set stats(StatLineBuilder? stats) => _$this._stats = stats;

  PlayerMatchLineBuilder() {
    PlayerMatchLine._defaults(this);
  }

  PlayerMatchLineBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _matchId = $v.matchId;
      _scheduledAt = $v.scheduledAt;
      _opponentName = $v.opponentName;
      _status = $v.status;
      _wasStarter = $v.wasStarter;
      _stats = $v.stats.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerMatchLine other) {
    _$v = other as _$PlayerMatchLine;
  }

  @override
  void update(void Function(PlayerMatchLineBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerMatchLine build() => _build();

  _$PlayerMatchLine _build() {
    _$PlayerMatchLine _$result;
    try {
      _$result = _$v ??
          _$PlayerMatchLine._(
            matchId: BuiltValueNullFieldError.checkNotNull(
                matchId, r'PlayerMatchLine', 'matchId'),
            scheduledAt: BuiltValueNullFieldError.checkNotNull(
                scheduledAt, r'PlayerMatchLine', 'scheduledAt'),
            opponentName: BuiltValueNullFieldError.checkNotNull(
                opponentName, r'PlayerMatchLine', 'opponentName'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'PlayerMatchLine', 'status'),
            wasStarter: BuiltValueNullFieldError.checkNotNull(
                wasStarter, r'PlayerMatchLine', 'wasStarter'),
            stats: stats.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'stats';
        stats.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerMatchLine', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
