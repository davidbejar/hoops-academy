// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_with_password.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantWithPassword extends TenantWithPassword {
  @override
  final String? temporaryPassword;
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

  factory _$TenantWithPassword(
          [void Function(TenantWithPasswordBuilder)? updates]) =>
      (TenantWithPasswordBuilder()..update(updates))._build();

  _$TenantWithPassword._(
      {this.temporaryPassword,
      required this.id,
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
  TenantWithPassword rebuild(
          void Function(TenantWithPasswordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantWithPasswordBuilder toBuilder() =>
      TenantWithPasswordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantWithPassword &&
        temporaryPassword == other.temporaryPassword &&
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
    _$hash = $jc(_$hash, temporaryPassword.hashCode);
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
    return (newBuiltValueToStringHelper(r'TenantWithPassword')
          ..add('temporaryPassword', temporaryPassword)
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

class TenantWithPasswordBuilder
    implements
        Builder<TenantWithPassword, TenantWithPasswordBuilder>,
        TenantBuilder {
  _$TenantWithPassword? _$v;

  String? _temporaryPassword;
  String? get temporaryPassword => _$this._temporaryPassword;
  set temporaryPassword(covariant String? temporaryPassword) =>
      _$this._temporaryPassword = temporaryPassword;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(covariant String? slug) => _$this._slug = slug;

  String? _name;
  String? get name => _$this._name;
  set name(covariant String? name) => _$this._name = name;

  TenantStatus? _status;
  TenantStatus? get status => _$this._status;
  set status(covariant TenantStatus? status) => _$this._status = status;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(covariant String? timezone) => _$this._timezone = timezone;

  Locale? _defaultLocale;
  Locale? get defaultLocale => _$this._defaultLocale;
  set defaultLocale(covariant Locale? defaultLocale) =>
      _$this._defaultLocale = defaultLocale;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(covariant DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _suspendedAt;
  DateTime? get suspendedAt => _$this._suspendedAt;
  set suspendedAt(covariant DateTime? suspendedAt) =>
      _$this._suspendedAt = suspendedAt;

  DateTime? _withdrawnAt;
  DateTime? get withdrawnAt => _$this._withdrawnAt;
  set withdrawnAt(covariant DateTime? withdrawnAt) =>
      _$this._withdrawnAt = withdrawnAt;

  Date? _retainUntil;
  Date? get retainUntil => _$this._retainUntil;
  set retainUntil(covariant Date? retainUntil) =>
      _$this._retainUntil = retainUntil;

  TenantWithPasswordBuilder() {
    TenantWithPassword._defaults(this);
  }

  TenantWithPasswordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _temporaryPassword = $v.temporaryPassword;
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
  void replace(covariant TenantWithPassword other) {
    _$v = other as _$TenantWithPassword;
  }

  @override
  void update(void Function(TenantWithPasswordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantWithPassword build() => _build();

  _$TenantWithPassword _build() {
    final _$result = _$v ??
        _$TenantWithPassword._(
          temporaryPassword: temporaryPassword,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'TenantWithPassword', 'id'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'TenantWithPassword', 'slug'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'TenantWithPassword', 'name'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'TenantWithPassword', 'status'),
          timezone: BuiltValueNullFieldError.checkNotNull(
              timezone, r'TenantWithPassword', 'timezone'),
          defaultLocale: BuiltValueNullFieldError.checkNotNull(
              defaultLocale, r'TenantWithPassword', 'defaultLocale'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'TenantWithPassword', 'createdAt'),
          suspendedAt: suspendedAt,
          withdrawnAt: withdrawnAt,
          retainUntil: retainUntil,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
