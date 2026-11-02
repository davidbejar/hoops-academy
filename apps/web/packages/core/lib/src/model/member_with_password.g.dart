// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_with_password.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MemberWithPassword extends MemberWithPassword {
  @override
  final String? temporaryPassword;
  @override
  final String personId;
  @override
  final String? userId;
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final String displayName;
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
  final String? playerId;
  @override
  final bool active;
  @override
  final InvitationStatus invitationStatus;
  @override
  final DateTime createdAt;

  factory _$MemberWithPassword(
          [void Function(MemberWithPasswordBuilder)? updates]) =>
      (MemberWithPasswordBuilder()..update(updates))._build();

  _$MemberWithPassword._(
      {this.temporaryPassword,
      required this.personId,
      this.userId,
      required this.givenName,
      required this.familyName,
      required this.displayName,
      this.email,
      this.phone,
      this.birthDate,
      this.gender,
      this.locale,
      required this.roles,
      this.playerId,
      required this.active,
      required this.invitationStatus,
      required this.createdAt})
      : super._();
  @override
  MemberWithPassword rebuild(
          void Function(MemberWithPasswordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MemberWithPasswordBuilder toBuilder() =>
      MemberWithPasswordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MemberWithPassword &&
        temporaryPassword == other.temporaryPassword &&
        personId == other.personId &&
        userId == other.userId &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        displayName == other.displayName &&
        email == other.email &&
        phone == other.phone &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        locale == other.locale &&
        roles == other.roles &&
        playerId == other.playerId &&
        active == other.active &&
        invitationStatus == other.invitationStatus &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, birthDate.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jc(_$hash, invitationStatus.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MemberWithPassword')
          ..add('temporaryPassword', temporaryPassword)
          ..add('personId', personId)
          ..add('userId', userId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('displayName', displayName)
          ..add('email', email)
          ..add('phone', phone)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('locale', locale)
          ..add('roles', roles)
          ..add('playerId', playerId)
          ..add('active', active)
          ..add('invitationStatus', invitationStatus)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class MemberWithPasswordBuilder
    implements
        Builder<MemberWithPassword, MemberWithPasswordBuilder>,
        MemberBuilder {
  _$MemberWithPassword? _$v;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(covariant String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(covariant String? personId) => _$this._personId = personId;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(covariant String? userId) => _$this._userId = userId;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(covariant String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(covariant String? familyName) =>
      _$this._familyName = familyName;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(covariant String? displayName) =>
      _$this._displayName = displayName;

  String? _email;
  String? get email => _$this._email;
  set email(covariant String? email) => _$this._email = email;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(covariant String? phone) => _$this._phone = phone;

  Date? _birthDate;
  Date? get birthDate => _$this._birthDate;
  set birthDate(covariant Date? birthDate) => _$this._birthDate = birthDate;

  Gender? _gender;
  Gender? get gender => _$this._gender;
  set gender(covariant Gender? gender) => _$this._gender = gender;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(covariant Locale? locale) => _$this._locale = locale;

  SetBuilder<TenantRole>? _roles;
  SetBuilder<TenantRole> get roles =>
      _$this._roles ??= SetBuilder<TenantRole>();
  set roles(covariant SetBuilder<TenantRole>? roles) => _$this._roles = roles;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  bool? _active;
  bool? get active => _$this._active;
  set active(covariant bool? active) => _$this._active = active;

  InvitationStatus? _invitationStatus;
  InvitationStatus? get invitationStatus => _$this._invitationStatus;
  set invitationStatus(covariant InvitationStatus? invitationStatus) =>
      _$this._invitationStatus = invitationStatus;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(covariant DateTime? createdAt) => _$this._createdAt = createdAt;

  MemberWithPasswordBuilder() {
    MemberWithPassword._defaults(this);
  }

  MemberWithPasswordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _temporaryPassword = $v.temporaryPassword;
      _personId = $v.personId;
      _userId = $v.userId;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _displayName = $v.displayName;
      _email = $v.email;
      _phone = $v.phone;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _locale = $v.locale;
      _roles = $v.roles.toBuilder();
      _playerId = $v.playerId;
      _active = $v.active;
      _invitationStatus = $v.invitationStatus;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant MemberWithPassword other) {
    _$v = other as _$MemberWithPassword;
  }

  @override
  void update(void Function(MemberWithPasswordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MemberWithPassword build() => _build();

  _$MemberWithPassword _build() {
    _$MemberWithPassword _$result;
    try {
      _$result = _$v ??
          _$MemberWithPassword._(
            temporaryPassword: temporaryPassword,
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'MemberWithPassword', 'personId'),
            userId: userId,
            givenName: BuiltValueNullFieldError.checkNotNull(
                givenName, r'MemberWithPassword', 'givenName'),
            familyName: BuiltValueNullFieldError.checkNotNull(
                familyName, r'MemberWithPassword', 'familyName'),
            displayName: BuiltValueNullFieldError.checkNotNull(
                displayName, r'MemberWithPassword', 'displayName'),
            email: email,
            phone: phone,
            birthDate: birthDate,
            gender: gender,
            locale: locale,
            roles: roles.build(),
            playerId: playerId,
            active: BuiltValueNullFieldError.checkNotNull(
                active, r'MemberWithPassword', 'active'),
            invitationStatus: BuiltValueNullFieldError.checkNotNull(
                invitationStatus, r'MemberWithPassword', 'invitationStatus'),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'MemberWithPassword', 'createdAt'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MemberWithPassword', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
