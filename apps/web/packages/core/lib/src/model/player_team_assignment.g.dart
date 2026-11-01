// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_team_assignment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerTeamAssignment extends PlayerTeamAssignment {
  @override
  final TeamRef team;
  @override
  final String? jerseyNumber;
  @override
  final int playUpLevels;
  @override
  final bool valid;

  factory _$PlayerTeamAssignment(
          [void Function(PlayerTeamAssignmentBuilder)? updates]) =>
      (PlayerTeamAssignmentBuilder()..update(updates))._build();

  _$PlayerTeamAssignment._(
      {required this.team,
      this.jerseyNumber,
      required this.playUpLevels,
      required this.valid})
      : super._();
  @override
  PlayerTeamAssignment rebuild(
          void Function(PlayerTeamAssignmentBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerTeamAssignmentBuilder toBuilder() =>
      PlayerTeamAssignmentBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerTeamAssignment &&
        team == other.team &&
        jerseyNumber == other.jerseyNumber &&
        playUpLevels == other.playUpLevels &&
        valid == other.valid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, team.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, playUpLevels.hashCode);
    _$hash = $jc(_$hash, valid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerTeamAssignment')
          ..add('team', team)
          ..add('jerseyNumber', jerseyNumber)
          ..add('playUpLevels', playUpLevels)
          ..add('valid', valid))
        .toString();
  }
}

class PlayerTeamAssignmentBuilder
    implements Builder<PlayerTeamAssignment, PlayerTeamAssignmentBuilder> {
  _$PlayerTeamAssignment? _$v;

  TeamRefBuilder? _team;
  TeamRefBuilder get team => _$this._team ??= TeamRefBuilder();
  set team(TeamRefBuilder? team) => _$this._team = team;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  int? _playUpLevels;
  int? get playUpLevels => _$this._playUpLevels;
  set playUpLevels(int? playUpLevels) => _$this._playUpLevels = playUpLevels;

  bool? _valid;
  bool? get valid => _$this._valid;
  set valid(bool? valid) => _$this._valid = valid;

  PlayerTeamAssignmentBuilder() {
    PlayerTeamAssignment._defaults(this);
  }

  PlayerTeamAssignmentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _team = $v.team.toBuilder();
      _jerseyNumber = $v.jerseyNumber;
      _playUpLevels = $v.playUpLevels;
      _valid = $v.valid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerTeamAssignment other) {
    _$v = other as _$PlayerTeamAssignment;
  }

  @override
  void update(void Function(PlayerTeamAssignmentBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerTeamAssignment build() => _build();

  _$PlayerTeamAssignment _build() {
    _$PlayerTeamAssignment _$result;
    try {
      _$result = _$v ??
          _$PlayerTeamAssignment._(
            team: team.build(),
            jerseyNumber: jerseyNumber,
            playUpLevels: BuiltValueNullFieldError.checkNotNull(
                playUpLevels, r'PlayerTeamAssignment', 'playUpLevels'),
            valid: BuiltValueNullFieldError.checkNotNull(
                valid, r'PlayerTeamAssignment', 'valid'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'team';
        team.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerTeamAssignment', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
