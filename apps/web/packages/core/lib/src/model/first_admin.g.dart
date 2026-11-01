// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_admin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FirstAdmin extends FirstAdmin {
  @override
  final String email;
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final Locale? locale;

  factory _$FirstAdmin([void Function(FirstAdminBuilder)? updates]) =>
      (FirstAdminBuilder()..update(updates))._build();

  _$FirstAdmin._(
      {required this.email,
      required this.givenName,
      required this.familyName,
      this.locale})
      : super._();
  @override
  FirstAdmin rebuild(void Function(FirstAdminBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FirstAdminBuilder toBuilder() => FirstAdminBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FirstAdmin &&
        email == other.email &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        locale == other.locale;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FirstAdmin')
          ..add('email', email)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('locale', locale))
        .toString();
  }
}

class FirstAdminBuilder implements Builder<FirstAdmin, FirstAdminBuilder> {
  _$FirstAdmin? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  FirstAdminBuilder() {
    FirstAdmin._defaults(this);
  }

  FirstAdminBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _locale = $v.locale;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FirstAdmin other) {
    _$v = other as _$FirstAdmin;
  }

  @override
  void update(void Function(FirstAdminBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FirstAdmin build() => _build();

  _$FirstAdmin _build() {
    final _$result = _$v ??
        _$FirstAdmin._(
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'FirstAdmin', 'email'),
          givenName: BuiltValueNullFieldError.checkNotNull(
              givenName, r'FirstAdmin', 'givenName'),
          familyName: BuiltValueNullFieldError.checkNotNull(
              familyName, r'FirstAdmin', 'familyName'),
          locale: locale,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
