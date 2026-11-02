// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_tenant_admin_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateTenantAdminRequest extends UpdateTenantAdminRequest {
  @override
  final String? givenName;
  @override
  final String? familyName;
  @override
  final String? email;

  factory _$UpdateTenantAdminRequest(
          [void Function(UpdateTenantAdminRequestBuilder)? updates]) =>
      (UpdateTenantAdminRequestBuilder()..update(updates))._build();

  _$UpdateTenantAdminRequest._({this.givenName, this.familyName, this.email})
      : super._();
  @override
  UpdateTenantAdminRequest rebuild(
          void Function(UpdateTenantAdminRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTenantAdminRequestBuilder toBuilder() =>
      UpdateTenantAdminRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTenantAdminRequest &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        email == other.email;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTenantAdminRequest')
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email))
        .toString();
  }
}

class UpdateTenantAdminRequestBuilder
    implements
        Builder<UpdateTenantAdminRequest, UpdateTenantAdminRequestBuilder> {
  _$UpdateTenantAdminRequest? _$v;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  UpdateTenantAdminRequestBuilder() {
    UpdateTenantAdminRequest._defaults(this);
  }

  UpdateTenantAdminRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _email = $v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTenantAdminRequest other) {
    _$v = other as _$UpdateTenantAdminRequest;
  }

  @override
  void update(void Function(UpdateTenantAdminRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTenantAdminRequest build() => _build();

  _$UpdateTenantAdminRequest _build() {
    final _$result = _$v ??
        _$UpdateTenantAdminRequest._(
          givenName: givenName,
          familyName: familyName,
          email: email,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
