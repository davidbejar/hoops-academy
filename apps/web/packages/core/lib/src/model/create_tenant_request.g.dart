// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_tenant_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateTenantRequest extends CreateTenantRequest {
  @override
  final String slug;
  @override
  final String name;
  @override
  final String timezone;
  @override
  final Locale defaultLocale;
  @override
  final FirstAdmin firstAdmin;

  factory _$CreateTenantRequest(
          [void Function(CreateTenantRequestBuilder)? updates]) =>
      (CreateTenantRequestBuilder()..update(updates))._build();

  _$CreateTenantRequest._(
      {required this.slug,
      required this.name,
      required this.timezone,
      required this.defaultLocale,
      required this.firstAdmin})
      : super._();
  @override
  CreateTenantRequest rebuild(
          void Function(CreateTenantRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTenantRequestBuilder toBuilder() =>
      CreateTenantRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTenantRequest &&
        slug == other.slug &&
        name == other.name &&
        timezone == other.timezone &&
        defaultLocale == other.defaultLocale &&
        firstAdmin == other.firstAdmin;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, defaultLocale.hashCode);
    _$hash = $jc(_$hash, firstAdmin.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTenantRequest')
          ..add('slug', slug)
          ..add('name', name)
          ..add('timezone', timezone)
          ..add('defaultLocale', defaultLocale)
          ..add('firstAdmin', firstAdmin))
        .toString();
  }
}

class CreateTenantRequestBuilder
    implements Builder<CreateTenantRequest, CreateTenantRequestBuilder> {
  _$CreateTenantRequest? _$v;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

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

  FirstAdminBuilder? _firstAdmin;
  FirstAdminBuilder get firstAdmin =>
      _$this._firstAdmin ??= FirstAdminBuilder();
  set firstAdmin(FirstAdminBuilder? firstAdmin) =>
      _$this._firstAdmin = firstAdmin;

  CreateTenantRequestBuilder() {
    CreateTenantRequest._defaults(this);
  }

  CreateTenantRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _slug = $v.slug;
      _name = $v.name;
      _timezone = $v.timezone;
      _defaultLocale = $v.defaultLocale;
      _firstAdmin = $v.firstAdmin.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTenantRequest other) {
    _$v = other as _$CreateTenantRequest;
  }

  @override
  void update(void Function(CreateTenantRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTenantRequest build() => _build();

  _$CreateTenantRequest _build() {
    _$CreateTenantRequest _$result;
    try {
      _$result = _$v ??
          _$CreateTenantRequest._(
            slug: BuiltValueNullFieldError.checkNotNull(
                slug, r'CreateTenantRequest', 'slug'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'CreateTenantRequest', 'name'),
            timezone: BuiltValueNullFieldError.checkNotNull(
                timezone, r'CreateTenantRequest', 'timezone'),
            defaultLocale: BuiltValueNullFieldError.checkNotNull(
                defaultLocale, r'CreateTenantRequest', 'defaultLocale'),
            firstAdmin: firstAdmin.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'firstAdmin';
        firstAdmin.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CreateTenantRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
