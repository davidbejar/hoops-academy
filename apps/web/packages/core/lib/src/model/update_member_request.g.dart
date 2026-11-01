// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_member_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMemberRequest extends UpdateMemberRequest {
  @override
  final String? givenName;
  @override
  final String? familyName;
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

  factory _$UpdateMemberRequest(
          [void Function(UpdateMemberRequestBuilder)? updates]) =>
      (UpdateMemberRequestBuilder()..update(updates))._build();

  _$UpdateMemberRequest._(
      {this.givenName,
      this.familyName,
      this.email,
      this.phone,
      this.birthDate,
      this.gender,
      this.locale})
      : super._();
  @override
  UpdateMemberRequest rebuild(
          void Function(UpdateMemberRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateMemberRequestBuilder toBuilder() =>
      UpdateMemberRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateMemberRequest &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        email == other.email &&
        phone == other.phone &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        locale == other.locale;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateMemberRequest')
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email)
          ..add('phone', phone)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('locale', locale))
        .toString();
  }
}

class UpdateMemberRequestBuilder
    implements Builder<UpdateMemberRequest, UpdateMemberRequestBuilder> {
  _$UpdateMemberRequest? _$v;

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

  UpdateMemberRequestBuilder() {
    UpdateMemberRequest._defaults(this);
  }

  UpdateMemberRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _email = $v.email;
      _phone = $v.phone;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _locale = $v.locale;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateMemberRequest other) {
    _$v = other as _$UpdateMemberRequest;
  }

  @override
  void update(void Function(UpdateMemberRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateMemberRequest build() => _build();

  _$UpdateMemberRequest _build() {
    final _$result = _$v ??
        _$UpdateMemberRequest._(
          givenName: givenName,
          familyName: familyName,
          email: email,
          phone: phone,
          birthDate: birthDate,
          gender: gender,
          locale: locale,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
