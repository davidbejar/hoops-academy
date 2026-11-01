// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_availability.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerAvailability extends PlayerAvailability {
  @override
  final String playerId;
  @override
  final bool available;
  @override
  final Date? expectedReturnOn;
  @override
  final BuiltList<String> injuries;

  factory _$PlayerAvailability(
          [void Function(PlayerAvailabilityBuilder)? updates]) =>
      (PlayerAvailabilityBuilder()..update(updates))._build();

  _$PlayerAvailability._(
      {required this.playerId,
      required this.available,
      this.expectedReturnOn,
      required this.injuries})
      : super._();
  @override
  PlayerAvailability rebuild(
          void Function(PlayerAvailabilityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerAvailabilityBuilder toBuilder() =>
      PlayerAvailabilityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerAvailability &&
        playerId == other.playerId &&
        available == other.available &&
        expectedReturnOn == other.expectedReturnOn &&
        injuries == other.injuries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, available.hashCode);
    _$hash = $jc(_$hash, expectedReturnOn.hashCode);
    _$hash = $jc(_$hash, injuries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerAvailability')
          ..add('playerId', playerId)
          ..add('available', available)
          ..add('expectedReturnOn', expectedReturnOn)
          ..add('injuries', injuries))
        .toString();
  }
}

class PlayerAvailabilityBuilder
    implements Builder<PlayerAvailability, PlayerAvailabilityBuilder> {
  _$PlayerAvailability? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  bool? _available;
  bool? get available => _$this._available;
  set available(bool? available) => _$this._available = available;

  Date? _expectedReturnOn;
  Date? get expectedReturnOn => _$this._expectedReturnOn;
  set expectedReturnOn(Date? expectedReturnOn) =>
      _$this._expectedReturnOn = expectedReturnOn;

  ListBuilder<String>? _injuries;
  ListBuilder<String> get injuries =>
      _$this._injuries ??= ListBuilder<String>();
  set injuries(ListBuilder<String>? injuries) => _$this._injuries = injuries;

  PlayerAvailabilityBuilder() {
    PlayerAvailability._defaults(this);
  }

  PlayerAvailabilityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _available = $v.available;
      _expectedReturnOn = $v.expectedReturnOn;
      _injuries = $v.injuries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerAvailability other) {
    _$v = other as _$PlayerAvailability;
  }

  @override
  void update(void Function(PlayerAvailabilityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerAvailability build() => _build();

  _$PlayerAvailability _build() {
    _$PlayerAvailability _$result;
    try {
      _$result = _$v ??
          _$PlayerAvailability._(
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlayerAvailability', 'playerId'),
            available: BuiltValueNullFieldError.checkNotNull(
                available, r'PlayerAvailability', 'available'),
            expectedReturnOn: expectedReturnOn,
            injuries: injuries.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'injuries';
        injuries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerAvailability', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
