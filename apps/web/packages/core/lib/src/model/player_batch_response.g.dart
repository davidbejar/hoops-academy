// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_batch_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerBatchResponse extends PlayerBatchResponse {
  @override
  final BuiltList<PlayerBrief> players;

  factory _$PlayerBatchResponse(
          [void Function(PlayerBatchResponseBuilder)? updates]) =>
      (PlayerBatchResponseBuilder()..update(updates))._build();

  _$PlayerBatchResponse._({required this.players}) : super._();
  @override
  PlayerBatchResponse rebuild(
          void Function(PlayerBatchResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerBatchResponseBuilder toBuilder() =>
      PlayerBatchResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerBatchResponse && players == other.players;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, players.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerBatchResponse')
          ..add('players', players))
        .toString();
  }
}

class PlayerBatchResponseBuilder
    implements Builder<PlayerBatchResponse, PlayerBatchResponseBuilder> {
  _$PlayerBatchResponse? _$v;

  ListBuilder<PlayerBrief>? _players;
  ListBuilder<PlayerBrief> get players =>
      _$this._players ??= ListBuilder<PlayerBrief>();
  set players(ListBuilder<PlayerBrief>? players) => _$this._players = players;

  PlayerBatchResponseBuilder() {
    PlayerBatchResponse._defaults(this);
  }

  PlayerBatchResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _players = $v.players.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerBatchResponse other) {
    _$v = other as _$PlayerBatchResponse;
  }

  @override
  void update(void Function(PlayerBatchResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerBatchResponse build() => _build();

  _$PlayerBatchResponse _build() {
    _$PlayerBatchResponse _$result;
    try {
      _$result = _$v ??
          _$PlayerBatchResponse._(
            players: players.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'players';
        players.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerBatchResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
