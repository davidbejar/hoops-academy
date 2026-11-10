// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_me_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMeRequest extends UpdateMeRequest {
  @override
  final Locale? locale;
  @override
  final String? givenName;
  @override
  final String? familyName;
  @override
  final String? tenantId;

  factory _$UpdateMeRequest([void Function(UpdateMeRequestBuilder)? updates]) =>
      (UpdateMeRequestBuilder()..update(updates))._build();

  _$UpdateMeRequest._(
      {this.locale, this.givenName, this.familyName, this.tenantId})
      : super._();
  @override
  UpdateMeRequest rebuild(void Function(UpdateMeRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateMeRequestBuilder toBuilder() => UpdateMeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateMeRequest &&
        locale == other.locale &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        tenantId == other.tenantId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateMeRequest')
          ..add('locale', locale)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('tenantId', tenantId))
        .toString();
  }
}

class UpdateMeRequestBuilder
    implements Builder<UpdateMeRequest, UpdateMeRequestBuilder> {
  _$UpdateMeRequest? _$v;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  UpdateMeRequestBuilder() {
    UpdateMeRequest._defaults(this);
  }

  UpdateMeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _locale = $v.locale;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _tenantId = $v.tenantId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateMeRequest other) {
    _$v = other as _$UpdateMeRequest;
  }

  @override
  void update(void Function(UpdateMeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateMeRequest build() => _build();

  _$UpdateMeRequest _build() {
    final _$result = _$v ??
        _$UpdateMeRequest._(
          locale: locale,
          givenName: givenName,
          familyName: familyName,
          tenantId: tenantId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
