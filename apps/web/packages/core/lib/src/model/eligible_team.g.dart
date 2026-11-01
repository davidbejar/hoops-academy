// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligible_team.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EligibleTeam extends EligibleTeam {
  @override
  final Team team;
  @override
  final EligibilityCheck eligibility;

  factory _$EligibleTeam([void Function(EligibleTeamBuilder)? updates]) =>
      (EligibleTeamBuilder()..update(updates))._build();

  _$EligibleTeam._({required this.team, required this.eligibility}) : super._();
  @override
  EligibleTeam rebuild(void Function(EligibleTeamBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EligibleTeamBuilder toBuilder() => EligibleTeamBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EligibleTeam &&
        team == other.team &&
        eligibility == other.eligibility;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, team.hashCode);
    _$hash = $jc(_$hash, eligibility.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EligibleTeam')
          ..add('team', team)
          ..add('eligibility', eligibility))
        .toString();
  }
}

class EligibleTeamBuilder
    implements Builder<EligibleTeam, EligibleTeamBuilder> {
  _$EligibleTeam? _$v;

  TeamBuilder? _team;
  TeamBuilder get team => _$this._team ??= TeamBuilder();
  set team(TeamBuilder? team) => _$this._team = team;

  EligibilityCheckBuilder? _eligibility;
  EligibilityCheckBuilder get eligibility =>
      _$this._eligibility ??= EligibilityCheckBuilder();
  set eligibility(EligibilityCheckBuilder? eligibility) =>
      _$this._eligibility = eligibility;

  EligibleTeamBuilder() {
    EligibleTeam._defaults(this);
  }

  EligibleTeamBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _team = $v.team.toBuilder();
      _eligibility = $v.eligibility.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EligibleTeam other) {
    _$v = other as _$EligibleTeam;
  }

  @override
  void update(void Function(EligibleTeamBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EligibleTeam build() => _build();

  _$EligibleTeam _build() {
    _$EligibleTeam _$result;
    try {
      _$result = _$v ??
          _$EligibleTeam._(
            team: team.build(),
            eligibility: eligibility.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'team';
        team.build();
        _$failedField = 'eligibility';
        eligibility.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EligibleTeam', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
