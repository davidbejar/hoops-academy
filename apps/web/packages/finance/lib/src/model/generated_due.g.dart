// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_due.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GeneratedDue extends GeneratedDue {
  @override
  final String? dueId;
  @override
  final String playerId;
  @override
  final String playerName;
  @override
  final String teamId;
  @override
  final int amountMinor;

  factory _$GeneratedDue([void Function(GeneratedDueBuilder)? updates]) =>
      (GeneratedDueBuilder()..update(updates))._build();

  _$GeneratedDue._(
      {this.dueId,
      required this.playerId,
      required this.playerName,
      required this.teamId,
      required this.amountMinor})
      : super._();
  @override
  GeneratedDue rebuild(void Function(GeneratedDueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GeneratedDueBuilder toBuilder() => GeneratedDueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GeneratedDue &&
        dueId == other.dueId &&
        playerId == other.playerId &&
        playerName == other.playerName &&
        teamId == other.teamId &&
        amountMinor == other.amountMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dueId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, playerName.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GeneratedDue')
          ..add('dueId', dueId)
          ..add('playerId', playerId)
          ..add('playerName', playerName)
          ..add('teamId', teamId)
          ..add('amountMinor', amountMinor))
        .toString();
  }
}

class GeneratedDueBuilder
    implements Builder<GeneratedDue, GeneratedDueBuilder> {
  _$GeneratedDue? _$v;

  String? _dueId;
  String? get dueId => _$this._dueId;
  set dueId(String? dueId) => _$this._dueId = dueId;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _playerName;
  String? get playerName => _$this._playerName;
  set playerName(String? playerName) => _$this._playerName = playerName;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  GeneratedDueBuilder() {
    GeneratedDue._defaults(this);
  }

  GeneratedDueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dueId = $v.dueId;
      _playerId = $v.playerId;
      _playerName = $v.playerName;
      _teamId = $v.teamId;
      _amountMinor = $v.amountMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GeneratedDue other) {
    _$v = other as _$GeneratedDue;
  }

  @override
  void update(void Function(GeneratedDueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GeneratedDue build() => _build();

  _$GeneratedDue _build() {
    final _$result = _$v ??
        _$GeneratedDue._(
          dueId: dueId,
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'GeneratedDue', 'playerId'),
          playerName: BuiltValueNullFieldError.checkNotNull(
              playerName, r'GeneratedDue', 'playerName'),
          teamId: BuiltValueNullFieldError.checkNotNull(
              teamId, r'GeneratedDue', 'teamId'),
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'GeneratedDue', 'amountMinor'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
