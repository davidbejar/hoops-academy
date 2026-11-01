// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_tenant_profile_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateTenantProfileRequest extends UpdateTenantProfileRequest {
  @override
  final String? name;
  @override
  final String? timezone;
  @override
  final Locale? defaultLocale;
  @override
  final String? contactEmail;
  @override
  final String? websiteUrl;

  factory _$UpdateTenantProfileRequest(
          [void Function(UpdateTenantProfileRequestBuilder)? updates]) =>
      (UpdateTenantProfileRequestBuilder()..update(updates))._build();

  _$UpdateTenantProfileRequest._(
      {this.name,
      this.timezone,
      this.defaultLocale,
      this.contactEmail,
      this.websiteUrl})
      : super._();
  @override
  UpdateTenantProfileRequest rebuild(
          void Function(UpdateTenantProfileRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTenantProfileRequestBuilder toBuilder() =>
      UpdateTenantProfileRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTenantProfileRequest &&
        name == other.name &&
        timezone == other.timezone &&
        defaultLocale == other.defaultLocale &&
        contactEmail == other.contactEmail &&
        websiteUrl == other.websiteUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, defaultLocale.hashCode);
    _$hash = $jc(_$hash, contactEmail.hashCode);
    _$hash = $jc(_$hash, websiteUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTenantProfileRequest')
          ..add('name', name)
          ..add('timezone', timezone)
          ..add('defaultLocale', defaultLocale)
          ..add('contactEmail', contactEmail)
          ..add('websiteUrl', websiteUrl))
        .toString();
  }
}

class UpdateTenantProfileRequestBuilder
    implements
        Builder<UpdateTenantProfileRequest, UpdateTenantProfileRequestBuilder> {
  _$UpdateTenantProfileRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  Locale? _defaultLocale;
  Locale? get defaultLocale => _$this._defaultLocale;
  set defaultLocale(Locale? defaultLocale) =>
      _$this._defaultLocale = defaultLocale;

  String? _contactEmail;
  String? get contactEmail => _$this._contactEmail;
  set contactEmail(String? contactEmail) => _$this._contactEmail = contactEmail;

  String? _websiteUrl;
  String? get websiteUrl => _$this._websiteUrl;
  set websiteUrl(String? websiteUrl) => _$this._websiteUrl = websiteUrl;

  UpdateTenantProfileRequestBuilder() {
    UpdateTenantProfileRequest._defaults(this);
  }

  UpdateTenantProfileRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _timezone = $v.timezone;
      _defaultLocale = $v.defaultLocale;
      _contactEmail = $v.contactEmail;
      _websiteUrl = $v.websiteUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTenantProfileRequest other) {
    _$v = other as _$UpdateTenantProfileRequest;
  }

  @override
  void update(void Function(UpdateTenantProfileRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTenantProfileRequest build() => _build();

  _$UpdateTenantProfileRequest _build() {
    final _$result = _$v ??
        _$UpdateTenantProfileRequest._(
          name: name,
          timezone: timezone,
          defaultLocale: defaultLocale,
          contactEmail: contactEmail,
          websiteUrl: websiteUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
