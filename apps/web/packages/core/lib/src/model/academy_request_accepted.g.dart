// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_request_accepted.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcademyRequestAccepted extends AcademyRequestAccepted {
  @override
  final AcademyRequest request;
  @override
  final Tenant tenant;
  @override
  final String? temporaryPassword;

  factory _$AcademyRequestAccepted(
          [void Function(AcademyRequestAcceptedBuilder)? updates]) =>
      (AcademyRequestAcceptedBuilder()..update(updates))._build();

  _$AcademyRequestAccepted._(
      {required this.request, required this.tenant, this.temporaryPassword})
      : super._();
  @override
  AcademyRequestAccepted rebuild(
          void Function(AcademyRequestAcceptedBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcademyRequestAcceptedBuilder toBuilder() =>
      AcademyRequestAcceptedBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcademyRequestAccepted &&
        request == other.request &&
        tenant == other.tenant &&
        temporaryPassword == other.temporaryPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, request.hashCode);
    _$hash = $jc(_$hash, tenant.hashCode);
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcademyRequestAccepted')
          ..add('request', request)
          ..add('tenant', tenant)
          ..add('temporaryPassword', temporaryPassword))
        .toString();
  }
}

class AcademyRequestAcceptedBuilder
    implements Builder<AcademyRequestAccepted, AcademyRequestAcceptedBuilder> {
  _$AcademyRequestAccepted? _$v;

  AcademyRequestBuilder? _request;
  AcademyRequestBuilder get request =>
      _$this._request ??= AcademyRequestBuilder();
  set request(AcademyRequestBuilder? request) => _$this._request = request;

  TenantBuilder? _tenant;
  TenantBuilder get tenant => _$this._tenant ??= TenantBuilder();
  set tenant(TenantBuilder? tenant) => _$this._tenant = tenant;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  AcademyRequestAcceptedBuilder() {
    AcademyRequestAccepted._defaults(this);
  }

  AcademyRequestAcceptedBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _request = $v.request.toBuilder();
      _tenant = $v.tenant.toBuilder();
      _temporaryPassword = $v.temporaryPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcademyRequestAccepted other) {
    _$v = other as _$AcademyRequestAccepted;
  }

  @override
  void update(void Function(AcademyRequestAcceptedBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcademyRequestAccepted build() => _build();

  _$AcademyRequestAccepted _build() {
    _$AcademyRequestAccepted _$result;
    try {
      _$result = _$v ??
          _$AcademyRequestAccepted._(
            request: request.build(),
            tenant: tenant.build(),
            temporaryPassword: temporaryPassword,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'request';
        request.build();
        _$failedField = 'tenant';
        tenant.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AcademyRequestAccepted', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
