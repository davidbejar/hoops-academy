// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_progress.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerProgress extends PlayerProgress {
  @override
  final String playerId;
  @override
  final CompletionStatus? status;
  @override
  final String? completionId;

  factory _$PlayerProgress([void Function(PlayerProgressBuilder)? updates]) =>
      (PlayerProgressBuilder()..update(updates))._build();

  _$PlayerProgress._({required this.playerId, this.status, this.completionId})
      : super._();
  @override
  PlayerProgress rebuild(void Function(PlayerProgressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerProgressBuilder toBuilder() => PlayerProgressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerProgress &&
        playerId == other.playerId &&
        status == other.status &&
        completionId == other.completionId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, completionId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerProgress')
          ..add('playerId', playerId)
          ..add('status', status)
          ..add('completionId', completionId))
        .toString();
  }
}

class PlayerProgressBuilder
    implements Builder<PlayerProgress, PlayerProgressBuilder> {
  _$PlayerProgress? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  CompletionStatus? _status;
  CompletionStatus? get status => _$this._status;
  set status(CompletionStatus? status) => _$this._status = status;

  String? _completionId;
  String? get completionId => _$this._completionId;
  set completionId(String? completionId) => _$this._completionId = completionId;

  PlayerProgressBuilder() {
    PlayerProgress._defaults(this);
  }

  PlayerProgressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _status = $v.status;
      _completionId = $v.completionId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerProgress other) {
    _$v = other as _$PlayerProgress;
  }

  @override
  void update(void Function(PlayerProgressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerProgress build() => _build();

  _$PlayerProgress _build() {
    final _$result = _$v ??
        _$PlayerProgress._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'PlayerProgress', 'playerId'),
          status: status,
          completionId: completionId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
