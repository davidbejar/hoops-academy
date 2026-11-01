// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_ref.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerRef extends PlayerRef {
  @override
  final String id;
  @override
  final String displayName;

  factory _$PlayerRef([void Function(PlayerRefBuilder)? updates]) =>
      (PlayerRefBuilder()..update(updates))._build();

  _$PlayerRef._({required this.id, required this.displayName}) : super._();
  @override
  PlayerRef rebuild(void Function(PlayerRefBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerRefBuilder toBuilder() => PlayerRefBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerRef &&
        id == other.id &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerRef')
          ..add('id', id)
          ..add('displayName', displayName))
        .toString();
  }
}

class PlayerRefBuilder implements Builder<PlayerRef, PlayerRefBuilder> {
  _$PlayerRef? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  PlayerRefBuilder() {
    PlayerRef._defaults(this);
  }

  PlayerRefBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerRef other) {
    _$v = other as _$PlayerRef;
  }

  @override
  void update(void Function(PlayerRefBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerRef build() => _build();

  _$PlayerRef _build() {
    final _$result = _$v ??
        _$PlayerRef._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PlayerRef', 'id'),
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'PlayerRef', 'displayName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
