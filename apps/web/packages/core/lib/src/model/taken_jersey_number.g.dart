// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taken_jersey_number.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TakenJerseyNumber extends TakenJerseyNumber {
  @override
  final String jerseyNumber;
  @override
  final PlayerRef player;

  factory _$TakenJerseyNumber(
          [void Function(TakenJerseyNumberBuilder)? updates]) =>
      (TakenJerseyNumberBuilder()..update(updates))._build();

  _$TakenJerseyNumber._({required this.jerseyNumber, required this.player})
      : super._();
  @override
  TakenJerseyNumber rebuild(void Function(TakenJerseyNumberBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TakenJerseyNumberBuilder toBuilder() =>
      TakenJerseyNumberBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TakenJerseyNumber &&
        jerseyNumber == other.jerseyNumber &&
        player == other.player;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TakenJerseyNumber')
          ..add('jerseyNumber', jerseyNumber)
          ..add('player', player))
        .toString();
  }
}

class TakenJerseyNumberBuilder
    implements Builder<TakenJerseyNumber, TakenJerseyNumberBuilder> {
  _$TakenJerseyNumber? _$v;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  PlayerRefBuilder? _player;
  PlayerRefBuilder get player => _$this._player ??= PlayerRefBuilder();
  set player(PlayerRefBuilder? player) => _$this._player = player;

  TakenJerseyNumberBuilder() {
    TakenJerseyNumber._defaults(this);
  }

  TakenJerseyNumberBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jerseyNumber = $v.jerseyNumber;
      _player = $v.player.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TakenJerseyNumber other) {
    _$v = other as _$TakenJerseyNumber;
  }

  @override
  void update(void Function(TakenJerseyNumberBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TakenJerseyNumber build() => _build();

  _$TakenJerseyNumber _build() {
    _$TakenJerseyNumber _$result;
    try {
      _$result = _$v ??
          _$TakenJerseyNumber._(
            jerseyNumber: BuiltValueNullFieldError.checkNotNull(
                jerseyNumber, r'TakenJerseyNumber', 'jerseyNumber'),
            player: player.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'player';
        player.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TakenJerseyNumber', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
