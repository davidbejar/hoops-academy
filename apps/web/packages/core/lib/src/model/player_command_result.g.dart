// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_command_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerCommandResult extends PlayerCommandResult {
  @override
  final Player player;
  @override
  final ApprovalRequest approvalRequest;
  @override
  final String? temporaryPassword;

  factory _$PlayerCommandResult(
          [void Function(PlayerCommandResultBuilder)? updates]) =>
      (PlayerCommandResultBuilder()..update(updates))._build();

  _$PlayerCommandResult._(
      {required this.player,
      required this.approvalRequest,
      this.temporaryPassword})
      : super._();
  @override
  PlayerCommandResult rebuild(
          void Function(PlayerCommandResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerCommandResultBuilder toBuilder() =>
      PlayerCommandResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerCommandResult &&
        player == other.player &&
        approvalRequest == other.approvalRequest &&
        temporaryPassword == other.temporaryPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, approvalRequest.hashCode);
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerCommandResult')
          ..add('player', player)
          ..add('approvalRequest', approvalRequest)
          ..add('temporaryPassword', temporaryPassword))
        .toString();
  }
}

class PlayerCommandResultBuilder
    implements Builder<PlayerCommandResult, PlayerCommandResultBuilder> {
  _$PlayerCommandResult? _$v;

  PlayerBuilder? _player;
  PlayerBuilder get player => _$this._player ??= PlayerBuilder();
  set player(PlayerBuilder? player) => _$this._player = player;

  ApprovalRequestBuilder? _approvalRequest;
  ApprovalRequestBuilder get approvalRequest =>
      _$this._approvalRequest ??= ApprovalRequestBuilder();
  set approvalRequest(ApprovalRequestBuilder? approvalRequest) =>
      _$this._approvalRequest = approvalRequest;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  PlayerCommandResultBuilder() {
    PlayerCommandResult._defaults(this);
  }

  PlayerCommandResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _player = $v.player.toBuilder();
      _approvalRequest = $v.approvalRequest.toBuilder();
      _temporaryPassword = $v.temporaryPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerCommandResult other) {
    _$v = other as _$PlayerCommandResult;
  }

  @override
  void update(void Function(PlayerCommandResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerCommandResult build() => _build();

  _$PlayerCommandResult _build() {
    _$PlayerCommandResult _$result;
    try {
      _$result = _$v ??
          _$PlayerCommandResult._(
            player: player.build(),
            approvalRequest: approvalRequest.build(),
            temporaryPassword: temporaryPassword,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'player';
        player.build();
        _$failedField = 'approvalRequest';
        approvalRequest.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerCommandResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
