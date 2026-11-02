// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_tenant_admin_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AddTenantAdminRequest extends AddTenantAdminRequest {
  @override
  final String email;
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final Locale? locale;

  factory _$AddTenantAdminRequest(
          [void Function(AddTenantAdminRequestBuilder)? updates]) =>
      (AddTenantAdminRequestBuilder()..update(updates))._build();

  _$AddTenantAdminRequest._(
      {required this.email,
      required this.givenName,
      required this.familyName,
      this.locale})
      : super._();
  @override
  AddTenantAdminRequest rebuild(
          void Function(AddTenantAdminRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddTenantAdminRequestBuilder toBuilder() =>
      AddTenantAdminRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddTenantAdminRequest &&
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
    return (newBuiltValueToStringHelper(r'AddTenantAdminRequest')
          ..add('email', email)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('locale', locale))
        .toString();
  }
}

class AddTenantAdminRequestBuilder
    implements Builder<AddTenantAdminRequest, AddTenantAdminRequestBuilder> {
  _$AddTenantAdminRequest? _$v;

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

  AddTenantAdminRequestBuilder() {
    AddTenantAdminRequest._defaults(this);
  }

  AddTenantAdminRequestBuilder get _$this {
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
  void replace(AddTenantAdminRequest other) {
    _$v = other as _$AddTenantAdminRequest;
  }

  @override
  void update(void Function(AddTenantAdminRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AddTenantAdminRequest build() => _build();

  _$AddTenantAdminRequest _build() {
    final _$result = _$v ??
        _$AddTenantAdminRequest._(
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'AddTenantAdminRequest', 'email'),
          givenName: BuiltValueNullFieldError.checkNotNull(
              givenName, r'AddTenantAdminRequest', 'givenName'),
          familyName: BuiltValueNullFieldError.checkNotNull(
              familyName, r'AddTenantAdminRequest', 'familyName'),
          locale: locale,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
