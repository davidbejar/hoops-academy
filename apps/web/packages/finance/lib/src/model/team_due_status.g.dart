// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_due_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamDueStatus extends TeamDueStatus {
  @override
  final String teamId;
  @override
  final BuiltList<PlayerDueStatus> players;

  factory _$TeamDueStatus([void Function(TeamDueStatusBuilder)? updates]) =>
      (TeamDueStatusBuilder()..update(updates))._build();

  _$TeamDueStatus._({required this.teamId, required this.players}) : super._();
  @override
  TeamDueStatus rebuild(void Function(TeamDueStatusBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamDueStatusBuilder toBuilder() => TeamDueStatusBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamDueStatus &&
        teamId == other.teamId &&
        players == other.players;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, players.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TeamDueStatus')
          ..add('teamId', teamId)
          ..add('players', players))
        .toString();
  }
}

class TeamDueStatusBuilder
    implements Builder<TeamDueStatus, TeamDueStatusBuilder> {
  _$TeamDueStatus? _$v;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  ListBuilder<PlayerDueStatus>? _players;
  ListBuilder<PlayerDueStatus> get players =>
      _$this._players ??= ListBuilder<PlayerDueStatus>();
  set players(ListBuilder<PlayerDueStatus>? players) =>
      _$this._players = players;

  TeamDueStatusBuilder() {
    TeamDueStatus._defaults(this);
  }

  TeamDueStatusBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _teamId = $v.teamId;
      _players = $v.players.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamDueStatus other) {
    _$v = other as _$TeamDueStatus;
  }

  @override
  void update(void Function(TeamDueStatusBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamDueStatus build() => _build();

  _$TeamDueStatus _build() {
    _$TeamDueStatus _$result;
    try {
      _$result = _$v ??
          _$TeamDueStatus._(
            teamId: BuiltValueNullFieldError.checkNotNull(
                teamId, r'TeamDueStatus', 'teamId'),
            players: players.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'players';
        players.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TeamDueStatus', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
