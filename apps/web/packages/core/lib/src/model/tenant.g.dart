// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Tenant extends Tenant {
  @override
  final String id;
  @override
  final String slug;
  @override
  final String name;
  @override
  final TenantStatus status;
  @override
  final String timezone;
  @override
  final Locale defaultLocale;
  @override
  final DateTime createdAt;
  @override
  final DateTime? suspendedAt;
  @override
  final DateTime? withdrawnAt;
  @override
  final Date? retainUntil;

  factory _$Tenant([void Function(TenantBuilder)? updates]) =>
      (TenantBuilder()..update(updates))._build();

  _$Tenant._(
      {required this.id,
      required this.slug,
      required this.name,
      required this.status,
      required this.timezone,
      required this.defaultLocale,
      required this.createdAt,
      this.suspendedAt,
      this.withdrawnAt,
      this.retainUntil})
      : super._();
  @override
  Tenant rebuild(void Function(TenantBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantBuilder toBuilder() => TenantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Tenant &&
        id == other.id &&
        slug == other.slug &&
        name == other.name &&
        status == other.status &&
        timezone == other.timezone &&
        defaultLocale == other.defaultLocale &&
        createdAt == other.createdAt &&
        suspendedAt == other.suspendedAt &&
        withdrawnAt == other.withdrawnAt &&
        retainUntil == other.retainUntil;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, defaultLocale.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, suspendedAt.hashCode);
    _$hash = $jc(_$hash, withdrawnAt.hashCode);
    _$hash = $jc(_$hash, retainUntil.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Tenant')
          ..add('id', id)
          ..add('slug', slug)
          ..add('name', name)
          ..add('status', status)
          ..add('timezone', timezone)
          ..add('defaultLocale', defaultLocale)
          ..add('createdAt', createdAt)
          ..add('suspendedAt', suspendedAt)
          ..add('withdrawnAt', withdrawnAt)
          ..add('retainUntil', retainUntil))
        .toString();
  }
}

class TenantBuilder implements Builder<Tenant, TenantBuilder> {
  _$Tenant? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  TenantStatus? _status;
  TenantStatus? get status => _$this._status;
  set status(TenantStatus? status) => _$this._status = status;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  Locale? _defaultLocale;
  Locale? get defaultLocale => _$this._defaultLocale;
  set defaultLocale(Locale? defaultLocale) =>
      _$this._defaultLocale = defaultLocale;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _suspendedAt;
  DateTime? get suspendedAt => _$this._suspendedAt;
  set suspendedAt(DateTime? suspendedAt) => _$this._suspendedAt = suspendedAt;

  DateTime? _withdrawnAt;
  DateTime? get withdrawnAt => _$this._withdrawnAt;
  set withdrawnAt(DateTime? withdrawnAt) => _$this._withdrawnAt = withdrawnAt;

  Date? _retainUntil;
  Date? get retainUntil => _$this._retainUntil;
  set retainUntil(Date? retainUntil) => _$this._retainUntil = retainUntil;

  TenantBuilder() {
    Tenant._defaults(this);
  }

  TenantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _slug = $v.slug;
      _name = $v.name;
      _status = $v.status;
      _timezone = $v.timezone;
      _defaultLocale = $v.defaultLocale;
      _createdAt = $v.createdAt;
      _suspendedAt = $v.suspendedAt;
      _withdrawnAt = $v.withdrawnAt;
      _retainUntil = $v.retainUntil;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Tenant other) {
    _$v = other as _$Tenant;
  }

  @override
  void update(void Function(TenantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Tenant build() => _build();

  _$Tenant _build() {
    final _$result = _$v ??
        _$Tenant._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Tenant', 'id'),
          slug: BuiltValueNullFieldError.checkNotNull(slug, r'Tenant', 'slug'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Tenant', 'name'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'Tenant', 'status'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'Tenant', 'timezone'),
          defaultLocale: BuiltValueNullFieldError.checkNotNull(
              defaultLocale, r'Tenant', 'defaultLocale'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'Tenant', 'createdAt'),
          suspendedAt: suspendedAt,
          withdrawnAt: withdrawnAt,
          retainUntil: retainUntil,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
