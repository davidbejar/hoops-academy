// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_roster.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamRoster extends TeamRoster {
  @override
  final String tenantId;
  @override
  final String teamId;
  @override
  final String seasonId;
  @override
  final String teamName;
  @override
  final BuiltList<RosterPlayer> players;
  @override
  final BuiltList<RosterStaff> staff;

  factory _$TeamRoster([void Function(TeamRosterBuilder)? updates]) =>
      (TeamRosterBuilder()..update(updates))._build();

  _$TeamRoster._(
      {required this.tenantId,
      required this.teamId,
      required this.seasonId,
      required this.teamName,
      required this.players,
      required this.staff})
      : super._();
  @override
  TeamRoster rebuild(void Function(TeamRosterBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamRosterBuilder toBuilder() => TeamRosterBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamRoster &&
        tenantId == other.tenantId &&
        teamId == other.teamId &&
        seasonId == other.seasonId &&
        teamName == other.teamName &&
        players == other.players &&
        staff == other.staff;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, teamName.hashCode);
    _$hash = $jc(_$hash, players.hashCode);
    _$hash = $jc(_$hash, staff.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TeamRoster')
          ..add('tenantId', tenantId)
          ..add('teamId', teamId)
          ..add('seasonId', seasonId)
          ..add('teamName', teamName)
          ..add('players', players)
          ..add('staff', staff))
        .toString();
  }
}

class TeamRosterBuilder implements Builder<TeamRoster, TeamRosterBuilder> {
  _$TeamRoster? _$v;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

  String? _teamName;
  String? get teamName => _$this._teamName;
  set teamName(String? teamName) => _$this._teamName = teamName;

  ListBuilder<RosterPlayer>? _players;
  ListBuilder<RosterPlayer> get players =>
      _$this._players ??= ListBuilder<RosterPlayer>();
  set players(ListBuilder<RosterPlayer>? players) => _$this._players = players;

  ListBuilder<RosterStaff>? _staff;
  ListBuilder<RosterStaff> get staff =>
      _$this._staff ??= ListBuilder<RosterStaff>();
  set staff(ListBuilder<RosterStaff>? staff) => _$this._staff = staff;

  TeamRosterBuilder() {
    TeamRoster._defaults(this);
  }

  TeamRosterBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenantId = $v.tenantId;
      _teamId = $v.teamId;
      _seasonId = $v.seasonId;
      _teamName = $v.teamName;
      _players = $v.players.toBuilder();
      _staff = $v.staff.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamRoster other) {
    _$v = other as _$TeamRoster;
  }

  @override
  void update(void Function(TeamRosterBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamRoster build() => _build();

  _$TeamRoster _build() {
    _$TeamRoster _$result;
    try {
      _$result = _$v ??
          _$TeamRoster._(
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'TeamRoster', 'tenantId'),
            teamId: BuiltValueNullFieldError.checkNotNull(
                teamId, r'TeamRoster', 'teamId'),
            seasonId: BuiltValueNullFieldError.checkNotNull(
                seasonId, r'TeamRoster', 'seasonId'),
            teamName: BuiltValueNullFieldError.checkNotNull(
                teamName, r'TeamRoster', 'teamName'),
            players: players.build(),
            staff: staff.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'players';
        players.build();
        _$failedField = 'staff';
        staff.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TeamRoster', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
