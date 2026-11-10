// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_user.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlatformUser extends PlatformUser {
  @override
  final String id;
  @override
  final String? email;
  @override
  final DateTime createdAt;
  @override
  final BuiltList<PlatformUserMembership> memberships;

  factory _$PlatformUser([void Function(PlatformUserBuilder)? updates]) =>
      (PlatformUserBuilder()..update(updates))._build();

  _$PlatformUser._(
      {required this.id,
      this.email,
      required this.createdAt,
      required this.memberships})
      : super._();
  @override
  PlatformUser rebuild(void Function(PlatformUserBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformUserBuilder toBuilder() => PlatformUserBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformUser &&
        id == other.id &&
        email == other.email &&
        createdAt == other.createdAt &&
        memberships == other.memberships;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, memberships.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlatformUser')
          ..add('id', id)
          ..add('email', email)
          ..add('createdAt', createdAt)
          ..add('memberships', memberships))
        .toString();
  }
}

class PlatformUserBuilder
    implements Builder<PlatformUser, PlatformUserBuilder> {
  _$PlatformUser? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  ListBuilder<PlatformUserMembership>? _memberships;
  ListBuilder<PlatformUserMembership> get memberships =>
      _$this._memberships ??= ListBuilder<PlatformUserMembership>();
  set memberships(ListBuilder<PlatformUserMembership>? memberships) =>
      _$this._memberships = memberships;

  PlatformUserBuilder() {
    PlatformUser._defaults(this);
  }

  PlatformUserBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _email = $v.email;
      _createdAt = $v.createdAt;
      _memberships = $v.memberships.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformUser other) {
    _$v = other as _$PlatformUser;
  }

  @override
  void update(void Function(PlatformUserBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformUser build() => _build();

  _$PlatformUser _build() {
    _$PlatformUser _$result;
    try {
      _$result = _$v ??
          _$PlatformUser._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlatformUser', 'id'),
            email: email,
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'PlatformUser', 'createdAt'),
            memberships: memberships.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'memberships';
        memberships.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlatformUser', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
