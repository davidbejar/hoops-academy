// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_due_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerDueStatus extends PlayerDueStatus {
  @override
  final String playerId;
  @override
  final String playerName;
  @override
  final bool upToDate;

  factory _$PlayerDueStatus([void Function(PlayerDueStatusBuilder)? updates]) =>
      (PlayerDueStatusBuilder()..update(updates))._build();

  _$PlayerDueStatus._(
      {required this.playerId,
      required this.playerName,
      required this.upToDate})
      : super._();
  @override
  PlayerDueStatus rebuild(void Function(PlayerDueStatusBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerDueStatusBuilder toBuilder() => PlayerDueStatusBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerDueStatus &&
        playerId == other.playerId &&
        playerName == other.playerName &&
        upToDate == other.upToDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, playerName.hashCode);
    _$hash = $jc(_$hash, upToDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerDueStatus')
          ..add('playerId', playerId)
          ..add('playerName', playerName)
          ..add('upToDate', upToDate))
        .toString();
  }
}

class PlayerDueStatusBuilder
    implements Builder<PlayerDueStatus, PlayerDueStatusBuilder> {
  _$PlayerDueStatus? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _playerName;
  String? get playerName => _$this._playerName;
  set playerName(String? playerName) => _$this._playerName = playerName;

  bool? _upToDate;
  bool? get upToDate => _$this._upToDate;
  set upToDate(bool? upToDate) => _$this._upToDate = upToDate;

  PlayerDueStatusBuilder() {
    PlayerDueStatus._defaults(this);
  }

  PlayerDueStatusBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _playerName = $v.playerName;
      _upToDate = $v.upToDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerDueStatus other) {
    _$v = other as _$PlayerDueStatus;
  }

  @override
  void update(void Function(PlayerDueStatusBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerDueStatus build() => _build();

  _$PlayerDueStatus _build() {
    final _$result = _$v ??
        _$PlayerDueStatus._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'PlayerDueStatus', 'playerId'),
          playerName: BuiltValueNullFieldError.checkNotNull(
              playerName, r'PlayerDueStatus', 'playerName'),
          upToDate: BuiltValueNullFieldError.checkNotNull(
              upToDate, r'PlayerDueStatus', 'upToDate'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
