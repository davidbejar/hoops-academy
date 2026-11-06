// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guardian_link_with_password.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GuardianLinkWithPassword extends GuardianLinkWithPassword {
  @override
  final String id;
  @override
  final PersonRef guardian;
  @override
  final PlayerRef player;
  @override
  final DateTime createdAt;
  @override
  final String? temporaryPassword;

  factory _$GuardianLinkWithPassword(
          [void Function(GuardianLinkWithPasswordBuilder)? updates]) =>
      (GuardianLinkWithPasswordBuilder()..update(updates))._build();

  _$GuardianLinkWithPassword._(
      {required this.id,
      required this.guardian,
      required this.player,
      required this.createdAt,
      this.temporaryPassword})
      : super._();
  @override
  GuardianLinkWithPassword rebuild(
          void Function(GuardianLinkWithPasswordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GuardianLinkWithPasswordBuilder toBuilder() =>
      GuardianLinkWithPasswordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GuardianLinkWithPassword &&
        id == other.id &&
        guardian == other.guardian &&
        player == other.player &&
        createdAt == other.createdAt &&
        temporaryPassword == other.temporaryPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, guardian.hashCode);
    _$hash = $jc(_$hash, player.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GuardianLinkWithPassword')
          ..add('id', id)
          ..add('guardian', guardian)
          ..add('player', player)
          ..add('createdAt', createdAt)
          ..add('temporaryPassword', temporaryPassword))
        .toString();
  }
}

class GuardianLinkWithPasswordBuilder
    implements
        Builder<GuardianLinkWithPassword, GuardianLinkWithPasswordBuilder> {
  _$GuardianLinkWithPassword? _$v;

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

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  GuardianLinkWithPasswordBuilder() {
    GuardianLinkWithPassword._defaults(this);
  }

  GuardianLinkWithPasswordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _guardian = $v.guardian.toBuilder();
      _player = $v.player.toBuilder();
      _createdAt = $v.createdAt;
      _temporaryPassword = $v.temporaryPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GuardianLinkWithPassword other) {
    _$v = other as _$GuardianLinkWithPassword;
  }

  @override
  void update(void Function(GuardianLinkWithPasswordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GuardianLinkWithPassword build() => _build();

  _$GuardianLinkWithPassword _build() {
    _$GuardianLinkWithPassword _$result;
    try {
      _$result = _$v ??
          _$GuardianLinkWithPassword._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'GuardianLinkWithPassword', 'id'),
            guardian: guardian.build(),
            player: player.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'GuardianLinkWithPassword', 'createdAt'),
            temporaryPassword: temporaryPassword,
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
            r'GuardianLinkWithPassword', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
