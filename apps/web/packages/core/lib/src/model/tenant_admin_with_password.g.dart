// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_admin_with_password.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantAdminWithPassword extends TenantAdminWithPassword {
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
  final TemporaryPasswordStatus temporaryPasswordStatus;
  @override
  final BuiltSet<TenantRole> otherRoles;
  @override
  final String? temporaryPassword;

  factory _$TenantAdminWithPassword(
          [void Function(TenantAdminWithPasswordBuilder)? updates]) =>
      (TenantAdminWithPasswordBuilder()..update(updates))._build();

  _$TenantAdminWithPassword._(
      {required this.personId,
      required this.givenName,
      required this.familyName,
      this.email,
      required this.invitationStatus,
      required this.temporaryPasswordStatus,
      required this.otherRoles,
      this.temporaryPassword})
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
        personId == other.personId &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        email == other.email &&
        invitationStatus == other.invitationStatus &&
        temporaryPasswordStatus == other.temporaryPasswordStatus &&
        otherRoles == other.otherRoles &&
        temporaryPassword == other.temporaryPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, invitationStatus.hashCode);
    _$hash = $jc(_$hash, temporaryPasswordStatus.hashCode);
    _$hash = $jc(_$hash, otherRoles.hashCode);
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantAdminWithPassword')
          ..add('personId', personId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email)
          ..add('invitationStatus', invitationStatus)
          ..add('temporaryPasswordStatus', temporaryPasswordStatus)
          ..add('otherRoles', otherRoles)
          ..add('temporaryPassword', temporaryPassword))
        .toString();
  }
}

class TenantAdminWithPasswordBuilder
    implements
        Builder<TenantAdminWithPassword, TenantAdminWithPasswordBuilder> {
  _$TenantAdminWithPassword? _$v;

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

  TemporaryPasswordStatus? _temporaryPasswordStatus;
  TemporaryPasswordStatus? get temporaryPasswordStatus =>
      _$this._temporaryPasswordStatus;
  set temporaryPasswordStatus(
          TemporaryPasswordStatus? temporaryPasswordStatus) =>
      _$this._temporaryPasswordStatus = temporaryPasswordStatus;

  SetBuilder<TenantRole>? _otherRoles;
  SetBuilder<TenantRole> get otherRoles =>
      _$this._otherRoles ??= SetBuilder<TenantRole>();
  set otherRoles(SetBuilder<TenantRole>? otherRoles) =>
      _$this._otherRoles = otherRoles;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  TenantAdminWithPasswordBuilder() {
    TenantAdminWithPassword._defaults(this);
  }

  TenantAdminWithPasswordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _personId = $v.personId;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _email = $v.email;
      _invitationStatus = $v.invitationStatus;
      _temporaryPasswordStatus = $v.temporaryPasswordStatus;
      _otherRoles = $v.otherRoles.toBuilder();
      _temporaryPassword = $v.temporaryPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantAdminWithPassword other) {
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
            temporaryPasswordStatus: BuiltValueNullFieldError.checkNotNull(
                temporaryPasswordStatus,
                r'TenantAdminWithPassword',
                'temporaryPasswordStatus'),
            otherRoles: otherRoles.build(),
            temporaryPassword: temporaryPassword,
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
