// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_member_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InviteMemberRequest extends InviteMemberRequest {
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  final Date? birthDate;
  @override
  final Gender? gender;
  @override
  final Locale? locale;
  @override
  final BuiltSet<TenantRole> roles;
  @override
  final bool? sendInvitation;

  factory _$InviteMemberRequest(
          [void Function(InviteMemberRequestBuilder)? updates]) =>
      (InviteMemberRequestBuilder()..update(updates))._build();

  _$InviteMemberRequest._(
      {required this.givenName,
      required this.familyName,
      this.email,
      this.phone,
      this.birthDate,
      this.gender,
      this.locale,
      required this.roles,
      this.sendInvitation})
      : super._();
  @override
  InviteMemberRequest rebuild(
          void Function(InviteMemberRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InviteMemberRequestBuilder toBuilder() =>
      InviteMemberRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InviteMemberRequest &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        email == other.email &&
        phone == other.phone &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        locale == other.locale &&
        roles == other.roles &&
        sendInvitation == other.sendInvitation;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, birthDate.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jc(_$hash, sendInvitation.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InviteMemberRequest')
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email)
          ..add('phone', phone)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('locale', locale)
          ..add('roles', roles)
          ..add('sendInvitation', sendInvitation))
        .toString();
  }
}

class InviteMemberRequestBuilder
    implements Builder<InviteMemberRequest, InviteMemberRequestBuilder> {
  _$InviteMemberRequest? _$v;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  Date? _birthDate;
  Date? get birthDate => _$this._birthDate;
  set birthDate(Date? birthDate) => _$this._birthDate = birthDate;

  Gender? _gender;
  Gender? get gender => _$this._gender;
  set gender(Gender? gender) => _$this._gender = gender;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  SetBuilder<TenantRole>? _roles;
  SetBuilder<TenantRole> get roles =>
      _$this._roles ??= SetBuilder<TenantRole>();
  set roles(SetBuilder<TenantRole>? roles) => _$this._roles = roles;

  bool? _sendInvitation;
  bool? get sendInvitation => _$this._sendInvitation;
  set sendInvitation(bool? sendInvitation) =>
      _$this._sendInvitation = sendInvitation;

  InviteMemberRequestBuilder() {
    InviteMemberRequest._defaults(this);
  }

  InviteMemberRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _email = $v.email;
      _phone = $v.phone;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _locale = $v.locale;
      _roles = $v.roles.toBuilder();
      _sendInvitation = $v.sendInvitation;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InviteMemberRequest other) {
    _$v = other as _$InviteMemberRequest;
  }

  @override
  void update(void Function(InviteMemberRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InviteMemberRequest build() => _build();

  _$InviteMemberRequest _build() {
    _$InviteMemberRequest _$result;
    try {
      _$result = _$v ??
          _$InviteMemberRequest._(
            givenName: BuiltValueNullFieldError.checkNotNull(
                givenName, r'InviteMemberRequest', 'givenName'),
            familyName: BuiltValueNullFieldError.checkNotNull(
                familyName, r'InviteMemberRequest', 'familyName'),
            email: email,
            phone: phone,
            birthDate: birthDate,
            gender: gender,
            locale: locale,
            roles: roles.build(),
            sendInvitation: sendInvitation,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'InviteMemberRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
