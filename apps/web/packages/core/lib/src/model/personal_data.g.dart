// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_data.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class PersonalDataBuilder {
  void replace(PersonalData other);
  void update(void Function(PersonalDataBuilder) updates);
  String? get givenName;
  set givenName(String? givenName);

  String? get familyName;
  set familyName(String? familyName);

  String? get email;
  set email(String? email);

  String? get phone;
  set phone(String? phone);

  Date? get birthDate;
  set birthDate(Date? birthDate);

  Gender? get gender;
  set gender(Gender? gender);

  Locale? get locale;
  set locale(Locale? locale);
}

class _$$PersonalData extends $PersonalData {
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

  factory _$$PersonalData([void Function($PersonalDataBuilder)? updates]) =>
      ($PersonalDataBuilder()..update(updates))._build();

  _$$PersonalData._(
      {required this.givenName,
      required this.familyName,
      this.email,
      this.phone,
      this.birthDate,
      this.gender,
      this.locale})
      : super._();
  @override
  $PersonalData rebuild(void Function($PersonalDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $PersonalDataBuilder toBuilder() => $PersonalDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $PersonalData &&
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
    return (newBuiltValueToStringHelper(r'$PersonalData')
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

class $PersonalDataBuilder
    implements
        Builder<$PersonalData, $PersonalDataBuilder>,
        PersonalDataBuilder {
  _$$PersonalData? _$v;

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

  $PersonalDataBuilder() {
    $PersonalData._defaults(this);
  }

  $PersonalDataBuilder get _$this {
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
  void replace(covariant $PersonalData other) {
    _$v = other as _$$PersonalData;
  }

  @override
  void update(void Function($PersonalDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $PersonalData build() => _build();

  _$$PersonalData _build() {
    final _$result = _$v ??
        _$$PersonalData._(
          givenName: BuiltValueNullFieldError.checkNotNull(
              givenName, r'$PersonalData', 'givenName'),
          familyName: BuiltValueNullFieldError.checkNotNull(
              familyName, r'$PersonalData', 'familyName'),
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
