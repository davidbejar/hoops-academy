// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Score extends Score {
  @override
  final int team;
  @override
  final int opponent;

  factory _$Score([void Function(ScoreBuilder)? updates]) =>
      (ScoreBuilder()..update(updates))._build();

  _$Score._({required this.team, required this.opponent}) : super._();
  @override
  Score rebuild(void Function(ScoreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ScoreBuilder toBuilder() => ScoreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Score && team == other.team && opponent == other.opponent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, team.hashCode);
    _$hash = $jc(_$hash, opponent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Score')
          ..add('team', team)
          ..add('opponent', opponent))
        .toString();
  }
}

class ScoreBuilder implements Builder<Score, ScoreBuilder> {
  _$Score? _$v;

  int? _team;
  int? get team => _$this._team;
  set team(int? team) => _$this._team = team;

  int? _opponent;
  int? get opponent => _$this._opponent;
  set opponent(int? opponent) => _$this._opponent = opponent;

  ScoreBuilder() {
    Score._defaults(this);
  }

  ScoreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _team = $v.team;
      _opponent = $v.opponent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Score other) {
    _$v = other as _$Score;
  }

  @override
  void update(void Function(ScoreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Score build() => _build();

  _$Score _build() {
    final _$result = _$v ??
        _$Score._(
          team: BuiltValueNullFieldError.checkNotNull(team, r'Score', 'team'),
          opponent: BuiltValueNullFieldError.checkNotNull(
              opponent, r'Score', 'opponent'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
