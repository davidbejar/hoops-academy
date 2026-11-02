// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_admin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantAdmin extends TenantAdmin {
  @override
  final String personId;
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final String? email;
  @override
  final InvitationStatus invitationStatus;
  @override
  final BuiltSet<TenantRole> otherRoles;

  factory _$TenantAdmin([void Function(TenantAdminBuilder)? updates]) =>
      (TenantAdminBuilder()..update(updates))._build();

  _$TenantAdmin._(
      {required this.personId,
      required this.givenName,
      required this.familyName,
      this.email,
      required this.invitationStatus,
      required this.otherRoles})
      : super._();
  @override
  TenantAdmin rebuild(void Function(TenantAdminBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantAdminBuilder toBuilder() => TenantAdminBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantAdmin &&
        personId == other.personId &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        email == other.email &&
        invitationStatus == other.invitationStatus &&
        otherRoles == other.otherRoles;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, invitationStatus.hashCode);
    _$hash = $jc(_$hash, otherRoles.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantAdmin')
          ..add('personId', personId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email)
          ..add('invitationStatus', invitationStatus)
          ..add('otherRoles', otherRoles))
        .toString();
  }
}

class TenantAdminBuilder implements Builder<TenantAdmin, TenantAdminBuilder> {
  _$TenantAdmin? _$v;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  InvitationStatus? _invitationStatus;
  InvitationStatus? get invitationStatus => _$this._invitationStatus;
  set invitationStatus(InvitationStatus? invitationStatus) =>
      _$this._invitationStatus = invitationStatus;

  SetBuilder<TenantRole>? _otherRoles;
  SetBuilder<TenantRole> get otherRoles =>
      _$this._otherRoles ??= SetBuilder<TenantRole>();
  set otherRoles(SetBuilder<TenantRole>? otherRoles) =>
      _$this._otherRoles = otherRoles;

  TenantAdminBuilder() {
    TenantAdmin._defaults(this);
  }

  TenantAdminBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _email = $v.email;
      _invitationStatus = $v.invitationStatus;
      _otherRoles = $v.otherRoles.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantAdmin other) {
    _$v = other as _$TenantAdmin;
  }

  @override
  void update(void Function(TenantAdminBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantAdmin build() => _build();

  _$TenantAdmin _build() {
    _$TenantAdmin _$result;
    try {
      _$result = _$v ??
          _$TenantAdmin._(
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'TenantAdmin', 'personId'),
            givenName: BuiltValueNullFieldError.checkNotNull(
                givenName, r'TenantAdmin', 'givenName'),
            familyName: BuiltValueNullFieldError.checkNotNull(
                familyName, r'TenantAdmin', 'familyName'),
            email: email,
            invitationStatus: BuiltValueNullFieldError.checkNotNull(
                invitationStatus, r'TenantAdmin', 'invitationStatus'),
            otherRoles: otherRoles.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'otherRoles';
        otherRoles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TenantAdmin', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
