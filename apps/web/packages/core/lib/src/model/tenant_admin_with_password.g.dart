// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_admin_with_password.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantAdminWithPassword extends TenantAdminWithPassword {
  @override
  final String? temporaryPassword;
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

  factory _$TenantAdminWithPassword(
          [void Function(TenantAdminWithPasswordBuilder)? updates]) =>
      (TenantAdminWithPasswordBuilder()..update(updates))._build();

  _$TenantAdminWithPassword._(
      {this.temporaryPassword,
      required this.personId,
      required this.givenName,
      required this.familyName,
      this.email,
      required this.invitationStatus,
      required this.otherRoles})
      : super._();
  @override
  TenantAdminWithPassword rebuild(
          void Function(TenantAdminWithPasswordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantAdminWithPasswordBuilder toBuilder() =>
      TenantAdminWithPasswordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantAdminWithPassword &&
        temporaryPassword == other.temporaryPassword &&
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
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
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
    return (newBuiltValueToStringHelper(r'TenantAdminWithPassword')
          ..add('temporaryPassword', temporaryPassword)
          ..add('personId', personId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email)
          ..add('invitationStatus', invitationStatus)
          ..add('otherRoles', otherRoles))
        .toString();
  }
}

class TenantAdminWithPasswordBuilder
    implements
        Builder<TenantAdminWithPassword, TenantAdminWithPasswordBuilder>,
        TenantAdminBuilder {
  _$TenantAdminWithPassword? _$v;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(covariant String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(covariant String? personId) => _$this._personId = personId;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(covariant String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(covariant String? familyName) =>
      _$this._familyName = familyName;

  String? _email;
  String? get email => _$this._email;
  set email(covariant String? email) => _$this._email = email;

  InvitationStatus? _invitationStatus;
  InvitationStatus? get invitationStatus => _$this._invitationStatus;
  set invitationStatus(covariant InvitationStatus? invitationStatus) =>
      _$this._invitationStatus = invitationStatus;

  SetBuilder<TenantRole>? _otherRoles;
  SetBuilder<TenantRole> get otherRoles =>
      _$this._otherRoles ??= SetBuilder<TenantRole>();
  set otherRoles(covariant SetBuilder<TenantRole>? otherRoles) =>
      _$this._otherRoles = otherRoles;

  TenantAdminWithPasswordBuilder() {
    TenantAdminWithPassword._defaults(this);
  }

  TenantAdminWithPasswordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _temporaryPassword = $v.temporaryPassword;
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
  void replace(covariant TenantAdminWithPassword other) {
    _$v = other as _$TenantAdminWithPassword;
  }

  @override
  void update(void Function(TenantAdminWithPasswordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantAdminWithPassword build() => _build();

  _$TenantAdminWithPassword _build() {
    _$TenantAdminWithPassword _$result;
    try {
      _$result = _$v ??
          _$TenantAdminWithPassword._(
            temporaryPassword: temporaryPassword,
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'TenantAdminWithPassword', 'personId'),
            givenName: BuiltValueNullFieldError.checkNotNull(
                givenName, r'TenantAdminWithPassword', 'givenName'),
            familyName: BuiltValueNullFieldError.checkNotNull(
                familyName, r'TenantAdminWithPassword', 'familyName'),
            email: email,
            invitationStatus: BuiltValueNullFieldError.checkNotNull(
                invitationStatus,
                r'TenantAdminWithPassword',
                'invitationStatus'),
            otherRoles: otherRoles.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'otherRoles';
        otherRoles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TenantAdminWithPassword', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
