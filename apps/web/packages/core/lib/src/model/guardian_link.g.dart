// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guardian_link.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GuardianLink extends GuardianLink {
  @override
  final String id;
  @override
  final PersonRef guardian;
  @override
  final PlayerRef player;
  @override
  final DateTime createdAt;

  factory _$GuardianLink([void Function(GuardianLinkBuilder)? updates]) =>
      (GuardianLinkBuilder()..update(updates))._build();

  _$GuardianLink._(
      {required this.id,
      required this.guardian,
      required this.player,
      required this.createdAt})
      : super._();
  @override
  GuardianLink rebuild(void Function(GuardianLinkBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GuardianLinkBuilder toBuilder() => GuardianLinkBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GuardianLink &&
        id == other.id &&
        guardian == other.guardian &&
        player == other.player &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, guardian.hashCode);
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GuardianLink')
          ..add('id', id)
          ..add('guardian', guardian)
          ..add('player', player)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class GuardianLinkBuilder
    implements Builder<GuardianLink, GuardianLinkBuilder> {
  _$GuardianLink? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  PersonRefBuilder? _guardian;
  PersonRefBuilder get guardian => _$this._guardian ??= PersonRefBuilder();
  set guardian(PersonRefBuilder? guardian) => _$this._guardian = guardian;

  PlayerRefBuilder? _player;
  PlayerRefBuilder get player => _$this._player ??= PlayerRefBuilder();
  set player(PlayerRefBuilder? player) => _$this._player = player;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  GuardianLinkBuilder() {
    GuardianLink._defaults(this);
  }

  GuardianLinkBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _guardian = $v.guardian.toBuilder();
      _player = $v.player.toBuilder();
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GuardianLink other) {
    _$v = other as _$GuardianLink;
  }

  @override
  void update(void Function(GuardianLinkBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GuardianLink build() => _build();

  _$GuardianLink _build() {
    _$GuardianLink _$result;
    try {
      _$result = _$v ??
          _$GuardianLink._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'GuardianLink', 'id'),
            guardian: guardian.build(),
            player: player.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'GuardianLink', 'createdAt'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'guardian';
        guardian.build();
        _$failedField = 'player';
        player.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'GuardianLink', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
