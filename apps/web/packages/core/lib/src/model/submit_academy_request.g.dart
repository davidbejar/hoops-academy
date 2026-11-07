// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_academy_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubmitAcademyRequest extends SubmitAcademyRequest {
  @override
  final String? name;
  @override
  final String email;
  @override
  final AcademyRequestRole role;
  @override
  final String academyName;
  @override
  final Locale? locale;
  @override
  final String? website;

  factory _$SubmitAcademyRequest(
          [void Function(SubmitAcademyRequestBuilder)? updates]) =>
      (SubmitAcademyRequestBuilder()..update(updates))._build();

  _$SubmitAcademyRequest._(
      {this.name,
      required this.email,
      required this.role,
      required this.academyName,
      this.locale,
      this.website})
      : super._();
  @override
  SubmitAcademyRequest rebuild(
          void Function(SubmitAcademyRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubmitAcademyRequestBuilder toBuilder() =>
      SubmitAcademyRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubmitAcademyRequest &&
        name == other.name &&
        email == other.email &&
        role == other.role &&
        academyName == other.academyName &&
        locale == other.locale &&
        website == other.website;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, academyName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, website.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubmitAcademyRequest')
          ..add('name', name)
          ..add('email', email)
          ..add('role', role)
          ..add('academyName', academyName)
          ..add('locale', locale)
          ..add('website', website))
        .toString();
  }
}

class SubmitAcademyRequestBuilder
    implements Builder<SubmitAcademyRequest, SubmitAcademyRequestBuilder> {
  _$SubmitAcademyRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  AcademyRequestRole? _role;
  AcademyRequestRole? get role => _$this._role;
  set role(AcademyRequestRole? role) => _$this._role = role;

  String? _academyName;
  String? get academyName => _$this._academyName;
  set academyName(String? academyName) => _$this._academyName = academyName;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  String? _website;
  String? get website => _$this._website;
  set website(String? website) => _$this._website = website;

  SubmitAcademyRequestBuilder() {
    SubmitAcademyRequest._defaults(this);
  }

  SubmitAcademyRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _email = $v.email;
      _role = $v.role;
      _academyName = $v.academyName;
      _locale = $v.locale;
      _website = $v.website;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubmitAcademyRequest other) {
    _$v = other as _$SubmitAcademyRequest;
  }

  @override
  void update(void Function(SubmitAcademyRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SubmitAcademyRequest build() => _build();

  _$SubmitAcademyRequest _build() {
    final _$result = _$v ??
        _$SubmitAcademyRequest._(
          name: name,
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'SubmitAcademyRequest', 'email'),
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'SubmitAcademyRequest', 'role'),
          academyName: BuiltValueNullFieldError.checkNotNull(
              academyName, r'SubmitAcademyRequest', 'academyName'),
          locale: locale,
          website: website,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
