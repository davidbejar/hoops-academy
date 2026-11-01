// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Me extends Me {
  @override
  final String userId;
  @override
  final String sub;
  @override
  final String? email;
  @override
  final String displayName;
  @override
  final Locale locale;
  @override
  final bool superAdmin;
  @override
  final BuiltList<Membership> memberships;

  factory _$Me([void Function(MeBuilder)? updates]) =>
      (MeBuilder()..update(updates))._build();

  _$Me._(
      {required this.userId,
      required this.sub,
      this.email,
      required this.displayName,
      required this.locale,
      required this.superAdmin,
      required this.memberships})
      : super._();
  @override
  Me rebuild(void Function(MeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MeBuilder toBuilder() => MeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Me &&
        userId == other.userId &&
        sub == other.sub &&
        email == other.email &&
        displayName == other.displayName &&
        locale == other.locale &&
        superAdmin == other.superAdmin &&
        memberships == other.memberships;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, sub.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, superAdmin.hashCode);
    _$hash = $jc(_$hash, memberships.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Me')
          ..add('userId', userId)
          ..add('sub', sub)
          ..add('email', email)
          ..add('displayName', displayName)
          ..add('locale', locale)
          ..add('superAdmin', superAdmin)
          ..add('memberships', memberships))
        .toString();
  }
}

class MeBuilder implements Builder<Me, MeBuilder> {
  _$Me? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _sub;
  String? get sub => _$this._sub;
  set sub(String? sub) => _$this._sub = sub;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  bool? _superAdmin;
  bool? get superAdmin => _$this._superAdmin;
  set superAdmin(bool? superAdmin) => _$this._superAdmin = superAdmin;

  ListBuilder<Membership>? _memberships;
  ListBuilder<Membership> get memberships =>
      _$this._memberships ??= ListBuilder<Membership>();
  set memberships(ListBuilder<Membership>? memberships) =>
      _$this._memberships = memberships;

  MeBuilder() {
    Me._defaults(this);
  }

  MeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _sub = $v.sub;
      _email = $v.email;
      _displayName = $v.displayName;
      _locale = $v.locale;
      _superAdmin = $v.superAdmin;
      _memberships = $v.memberships.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Me other) {
    _$v = other as _$Me;
  }

  @override
  void update(void Function(MeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Me build() => _build();

  _$Me _build() {
    _$Me _$result;
    try {
      _$result = _$v ??
          _$Me._(
            userId:
                BuiltValueNullFieldError.checkNotNull(userId, r'Me', 'userId'),
            sub: BuiltValueNullFieldError.checkNotNull(sub, r'Me', 'sub'),
            email: email,
            displayName: BuiltValueNullFieldError.checkNotNull(
                displayName, r'Me', 'displayName'),
            locale:
                BuiltValueNullFieldError.checkNotNull(locale, r'Me', 'locale'),
            superAdmin: BuiltValueNullFieldError.checkNotNull(
                superAdmin, r'Me', 'superAdmin'),
            memberships: memberships.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'memberships';
        memberships.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Me', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
