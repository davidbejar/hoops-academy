// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_profile.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantProfile extends TenantProfile {
  @override
  final String id;
  @override
  final String slug;
  @override
  final String name;
  @override
  final String timezone;
  @override
  final Locale defaultLocale;
  @override
  final String? contactEmail;
  @override
  final String? websiteUrl;
  @override
  final bool hasLogo;
  @override
  final String? logoEtag;

  factory _$TenantProfile([void Function(TenantProfileBuilder)? updates]) =>
      (TenantProfileBuilder()..update(updates))._build();

  _$TenantProfile._(
      {required this.id,
      required this.slug,
      required this.name,
      required this.timezone,
      required this.defaultLocale,
      this.contactEmail,
      this.websiteUrl,
      required this.hasLogo,
      this.logoEtag})
      : super._();
  @override
  TenantProfile rebuild(void Function(TenantProfileBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantProfileBuilder toBuilder() => TenantProfileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantProfile &&
        id == other.id &&
        slug == other.slug &&
        name == other.name &&
        timezone == other.timezone &&
        defaultLocale == other.defaultLocale &&
        contactEmail == other.contactEmail &&
        websiteUrl == other.websiteUrl &&
        hasLogo == other.hasLogo &&
        logoEtag == other.logoEtag;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, defaultLocale.hashCode);
    _$hash = $jc(_$hash, contactEmail.hashCode);
    _$hash = $jc(_$hash, websiteUrl.hashCode);
    _$hash = $jc(_$hash, hasLogo.hashCode);
    _$hash = $jc(_$hash, logoEtag.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantProfile')
          ..add('id', id)
          ..add('slug', slug)
          ..add('name', name)
          ..add('timezone', timezone)
          ..add('defaultLocale', defaultLocale)
          ..add('contactEmail', contactEmail)
          ..add('websiteUrl', websiteUrl)
          ..add('hasLogo', hasLogo)
          ..add('logoEtag', logoEtag))
        .toString();
  }
}

class TenantProfileBuilder
    implements Builder<TenantProfile, TenantProfileBuilder> {
  _$TenantProfile? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

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

  String? _contactEmail;
  String? get contactEmail => _$this._contactEmail;
  set contactEmail(String? contactEmail) => _$this._contactEmail = contactEmail;

  String? _websiteUrl;
  String? get websiteUrl => _$this._websiteUrl;
  set websiteUrl(String? websiteUrl) => _$this._websiteUrl = websiteUrl;

  bool? _hasLogo;
  bool? get hasLogo => _$this._hasLogo;
  set hasLogo(bool? hasLogo) => _$this._hasLogo = hasLogo;

  String? _logoEtag;
  String? get logoEtag => _$this._logoEtag;
  set logoEtag(String? logoEtag) => _$this._logoEtag = logoEtag;

  TenantProfileBuilder() {
    TenantProfile._defaults(this);
  }

  TenantProfileBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _slug = $v.slug;
      _name = $v.name;
      _timezone = $v.timezone;
      _defaultLocale = $v.defaultLocale;
      _contactEmail = $v.contactEmail;
      _websiteUrl = $v.websiteUrl;
      _hasLogo = $v.hasLogo;
      _logoEtag = $v.logoEtag;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantProfile other) {
    _$v = other as _$TenantProfile;
  }

  @override
  void update(void Function(TenantProfileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantProfile build() => _build();

  _$TenantProfile _build() {
    final _$result = _$v ??
        _$TenantProfile._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'TenantProfile', 'id'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'TenantProfile', 'slug'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'TenantProfile', 'name'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'TenantProfile', 'timezone'),
          defaultLocale: BuiltValueNullFieldError.checkNotNull(
              defaultLocale, r'TenantProfile', 'defaultLocale'),
          contactEmail: contactEmail,
          websiteUrl: websiteUrl,
          hasLogo: BuiltValueNullFieldError.checkNotNull(
              hasLogo, r'TenantProfile', 'hasLogo'),
          logoEtag: logoEtag,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
