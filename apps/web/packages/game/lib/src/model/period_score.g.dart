// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_score.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PeriodScore extends PeriodScore {
  @override
  final int period;
  @override
  final int team;
  @override
  final int opponent;

  factory _$PeriodScore([void Function(PeriodScoreBuilder)? updates]) =>
      (PeriodScoreBuilder()..update(updates))._build();

  _$PeriodScore._(
      {required this.period, required this.team, required this.opponent})
      : super._();
  @override
  PeriodScore rebuild(void Function(PeriodScoreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PeriodScoreBuilder toBuilder() => PeriodScoreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PeriodScore &&
        period == other.period &&
        team == other.team &&
        opponent == other.opponent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, team.hashCode);
    _$hash = $jc(_$hash, opponent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PeriodScore')
          ..add('period', period)
          ..add('team', team)
          ..add('opponent', opponent))
        .toString();
  }
}

class PeriodScoreBuilder implements Builder<PeriodScore, PeriodScoreBuilder> {
  _$PeriodScore? _$v;

  int? _period;
  int? get period => _$this._period;
  set period(int? period) => _$this._period = period;

  int? _team;
  int? get team => _$this._team;
  set team(int? team) => _$this._team = team;

  int? _opponent;
  int? get opponent => _$this._opponent;
  set opponent(int? opponent) => _$this._opponent = opponent;

  PeriodScoreBuilder() {
    PeriodScore._defaults(this);
  }

  PeriodScoreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _period = $v.period;
      _team = $v.team;
      _opponent = $v.opponent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PeriodScore other) {
    _$v = other as _$PeriodScore;
  }

  @override
  void update(void Function(PeriodScoreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PeriodScore build() => _build();

  _$PeriodScore _build() {
    final _$result = _$v ??
        _$PeriodScore._(
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'PeriodScore', 'period'),
          team: BuiltValueNullFieldError.checkNotNull(
              team, r'PeriodScore', 'team'),
          opponent: BuiltValueNullFieldError.checkNotNull(
              opponent, r'PeriodScore', 'opponent'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
