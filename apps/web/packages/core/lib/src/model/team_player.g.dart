// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_player.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamPlayer extends TeamPlayer {
  @override
  final PlayerRef player;
  @override
  final String teamId;
  @override
  final String? jerseyNumber;
  @override
  final Date joinedOn;
  @override
  final Date? leftOn;
  @override
  final int playUpLevels;
  @override
  final DateTime? invalidatedAt;
  @override
  final EligibilityReason? invalidReason;
  @override
  final PlayerStatus playerStatus;

  factory _$TeamPlayer([void Function(TeamPlayerBuilder)? updates]) =>
      (TeamPlayerBuilder()..update(updates))._build();

  _$TeamPlayer._(
      {required this.player,
      required this.teamId,
      this.jerseyNumber,
      required this.joinedOn,
      this.leftOn,
      required this.playUpLevels,
      this.invalidatedAt,
      this.invalidReason,
      required this.playerStatus})
      : super._();
  @override
  TeamPlayer rebuild(void Function(TeamPlayerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamPlayerBuilder toBuilder() => TeamPlayerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamPlayer &&
        player == other.player &&
        teamId == other.teamId &&
        jerseyNumber == other.jerseyNumber &&
        joinedOn == other.joinedOn &&
        leftOn == other.leftOn &&
        playUpLevels == other.playUpLevels &&
        invalidatedAt == other.invalidatedAt &&
        invalidReason == other.invalidReason &&
        playerStatus == other.playerStatus;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, joinedOn.hashCode);
    _$hash = $jc(_$hash, leftOn.hashCode);
    _$hash = $jc(_$hash, playUpLevels.hashCode);
    _$hash = $jc(_$hash, invalidatedAt.hashCode);
    _$hash = $jc(_$hash, invalidReason.hashCode);
    _$hash = $jc(_$hash, playerStatus.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TeamPlayer')
          ..add('player', player)
          ..add('teamId', teamId)
          ..add('jerseyNumber', jerseyNumber)
          ..add('joinedOn', joinedOn)
          ..add('leftOn', leftOn)
          ..add('playUpLevels', playUpLevels)
          ..add('invalidatedAt', invalidatedAt)
          ..add('invalidReason', invalidReason)
          ..add('playerStatus', playerStatus))
        .toString();
  }
}

class TeamPlayerBuilder implements Builder<TeamPlayer, TeamPlayerBuilder> {
  _$TeamPlayer? _$v;

  PlayerRefBuilder? _player;
  PlayerRefBuilder get player => _$this._player ??= PlayerRefBuilder();
  set player(PlayerRefBuilder? player) => _$this._player = player;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  Date? _joinedOn;
  Date? get joinedOn => _$this._joinedOn;
  set joinedOn(Date? joinedOn) => _$this._joinedOn = joinedOn;

  Date? _leftOn;
  Date? get leftOn => _$this._leftOn;
  set leftOn(Date? leftOn) => _$this._leftOn = leftOn;

  int? _playUpLevels;
  int? get playUpLevels => _$this._playUpLevels;
  set playUpLevels(int? playUpLevels) => _$this._playUpLevels = playUpLevels;

  DateTime? _invalidatedAt;
  DateTime? get invalidatedAt => _$this._invalidatedAt;
  set invalidatedAt(DateTime? invalidatedAt) =>
      _$this._invalidatedAt = invalidatedAt;

  EligibilityReason? _invalidReason;
  EligibilityReason? get invalidReason => _$this._invalidReason;
  set invalidReason(EligibilityReason? invalidReason) =>
      _$this._invalidReason = invalidReason;

  PlayerStatus? _playerStatus;
  PlayerStatus? get playerStatus => _$this._playerStatus;
  set playerStatus(PlayerStatus? playerStatus) =>
      _$this._playerStatus = playerStatus;

  TeamPlayerBuilder() {
    TeamPlayer._defaults(this);
  }

  TeamPlayerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _player = $v.player.toBuilder();
      _teamId = $v.teamId;
      _jerseyNumber = $v.jerseyNumber;
      _joinedOn = $v.joinedOn;
      _leftOn = $v.leftOn;
      _playUpLevels = $v.playUpLevels;
      _invalidatedAt = $v.invalidatedAt;
      _invalidReason = $v.invalidReason;
      _playerStatus = $v.playerStatus;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamPlayer other) {
    _$v = other as _$TeamPlayer;
  }

  @override
  void update(void Function(TeamPlayerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamPlayer build() => _build();

  _$TeamPlayer _build() {
    _$TeamPlayer _$result;
    try {
      _$result = _$v ??
          _$TeamPlayer._(
            player: player.build(),
            teamId: BuiltValueNullFieldError.checkNotNull(
                teamId, r'TeamPlayer', 'teamId'),
            jerseyNumber: jerseyNumber,
            joinedOn: BuiltValueNullFieldError.checkNotNull(
                joinedOn, r'TeamPlayer', 'joinedOn'),
            leftOn: leftOn,
            playUpLevels: BuiltValueNullFieldError.checkNotNull(
                playUpLevels, r'TeamPlayer', 'playUpLevels'),
            invalidatedAt: invalidatedAt,
            invalidReason: invalidReason,
            playerStatus: BuiltValueNullFieldError.checkNotNull(
                playerStatus, r'TeamPlayer', 'playerStatus'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'player';
        player.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TeamPlayer', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
