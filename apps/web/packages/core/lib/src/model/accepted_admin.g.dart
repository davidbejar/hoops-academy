// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted_admin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcceptedAdmin extends AcceptedAdmin {
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final Locale? locale;

  factory _$AcceptedAdmin([void Function(AcceptedAdminBuilder)? updates]) =>
      (AcceptedAdminBuilder()..update(updates))._build();

  _$AcceptedAdmin._(
      {required this.givenName, required this.familyName, this.locale})
      : super._();
  @override
  AcceptedAdmin rebuild(void Function(AcceptedAdminBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcceptedAdminBuilder toBuilder() => AcceptedAdminBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptedAdmin &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        locale == other.locale;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptedAdmin')
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('locale', locale))
        .toString();
  }
}

class AcceptedAdminBuilder
    implements Builder<AcceptedAdmin, AcceptedAdminBuilder> {
  _$AcceptedAdmin? _$v;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  AcceptedAdminBuilder() {
    AcceptedAdmin._defaults(this);
  }

  AcceptedAdminBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _locale = $v.locale;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptedAdmin other) {
    _$v = other as _$AcceptedAdmin;
  }

  @override
  void update(void Function(AcceptedAdminBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptedAdmin build() => _build();

  _$AcceptedAdmin _build() {
    final _$result = _$v ??
        _$AcceptedAdmin._(
          givenName: BuiltValueNullFieldError.checkNotNull(
              givenName, r'AcceptedAdmin', 'givenName'),
          familyName: BuiltValueNullFieldError.checkNotNull(
              familyName, r'AcceptedAdmin', 'familyName'),
          locale: locale,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
