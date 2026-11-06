// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_guardian_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateGuardianRequest extends CreateGuardianRequest {
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final String? email;
  @override
  final String? phone;
  @override
  final Locale? locale;
  @override
  final String playerId;

  factory _$CreateGuardianRequest(
          [void Function(CreateGuardianRequestBuilder)? updates]) =>
      (CreateGuardianRequestBuilder()..update(updates))._build();

  _$CreateGuardianRequest._(
      {required this.givenName,
      required this.familyName,
      this.email,
      this.phone,
      this.locale,
      required this.playerId})
      : super._();
  @override
  CreateGuardianRequest rebuild(
          void Function(CreateGuardianRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateGuardianRequestBuilder toBuilder() =>
      CreateGuardianRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateGuardianRequest &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        email == other.email &&
        phone == other.phone &&
        locale == other.locale &&
        playerId == other.playerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateGuardianRequest')
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('email', email)
          ..add('phone', phone)
          ..add('locale', locale)
          ..add('playerId', playerId))
        .toString();
  }
}

class CreateGuardianRequestBuilder
    implements Builder<CreateGuardianRequest, CreateGuardianRequestBuilder> {
  _$CreateGuardianRequest? _$v;

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

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  CreateGuardianRequestBuilder() {
    CreateGuardianRequest._defaults(this);
  }

  CreateGuardianRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _email = $v.email;
      _phone = $v.phone;
      _locale = $v.locale;
      _playerId = $v.playerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateGuardianRequest other) {
    _$v = other as _$CreateGuardianRequest;
  }

  @override
  void update(void Function(CreateGuardianRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateGuardianRequest build() => _build();

  _$CreateGuardianRequest _build() {
    final _$result = _$v ??
        _$CreateGuardianRequest._(
          givenName: BuiltValueNullFieldError.checkNotNull(
              givenName, r'CreateGuardianRequest', 'givenName'),
          familyName: BuiltValueNullFieldError.checkNotNull(
              familyName, r'CreateGuardianRequest', 'familyName'),
          email: email,
          phone: phone,
          locale: locale,
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'CreateGuardianRequest', 'playerId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
