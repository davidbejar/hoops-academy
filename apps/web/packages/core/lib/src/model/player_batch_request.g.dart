// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_batch_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerBatchRequest extends PlayerBatchRequest {
  @override
  final BuiltSet<String> playerIds;

  factory _$PlayerBatchRequest(
          [void Function(PlayerBatchRequestBuilder)? updates]) =>
      (PlayerBatchRequestBuilder()..update(updates))._build();

  _$PlayerBatchRequest._({required this.playerIds}) : super._();
  @override
  PlayerBatchRequest rebuild(
          void Function(PlayerBatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerBatchRequestBuilder toBuilder() =>
      PlayerBatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerBatchRequest && playerIds == other.playerIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerBatchRequest')
          ..add('playerIds', playerIds))
        .toString();
  }
}

class PlayerBatchRequestBuilder
    implements Builder<PlayerBatchRequest, PlayerBatchRequestBuilder> {
  _$PlayerBatchRequest? _$v;

  SetBuilder<String>? _playerIds;
  SetBuilder<String> get playerIds =>
      _$this._playerIds ??= SetBuilder<String>();
  set playerIds(SetBuilder<String>? playerIds) => _$this._playerIds = playerIds;

  PlayerBatchRequestBuilder() {
    PlayerBatchRequest._defaults(this);
  }

  PlayerBatchRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerIds = $v.playerIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerBatchRequest other) {
    _$v = other as _$PlayerBatchRequest;
  }

  @override
  void update(void Function(PlayerBatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerBatchRequest build() => _build();

  _$PlayerBatchRequest _build() {
    _$PlayerBatchRequest _$result;
    try {
      _$result = _$v ??
          _$PlayerBatchRequest._(
            playerIds: playerIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'playerIds';
        playerIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerBatchRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
