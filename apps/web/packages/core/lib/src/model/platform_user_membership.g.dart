// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_user_membership.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlatformUserMembership extends PlatformUserMembership {
  @override
  final String tenantId;
  @override
  final String tenantName;
  @override
  final String tenantSlug;
  @override
  final TenantStatus tenantStatus;
  @override
  final String personId;
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final BuiltSet<TenantRole> roles;
  @override
  final bool active;

  factory _$PlatformUserMembership(
          [void Function(PlatformUserMembershipBuilder)? updates]) =>
      (PlatformUserMembershipBuilder()..update(updates))._build();

  _$PlatformUserMembership._(
      {required this.tenantId,
      required this.tenantName,
      required this.tenantSlug,
      required this.tenantStatus,
      required this.personId,
      required this.givenName,
      required this.familyName,
      required this.roles,
      required this.active})
      : super._();
  @override
  PlatformUserMembership rebuild(
          void Function(PlatformUserMembershipBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformUserMembershipBuilder toBuilder() =>
      PlatformUserMembershipBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformUserMembership &&
        tenantId == other.tenantId &&
        tenantName == other.tenantName &&
        tenantSlug == other.tenantSlug &&
        tenantStatus == other.tenantStatus &&
        personId == other.personId &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        roles == other.roles &&
        active == other.active;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, tenantName.hashCode);
    _$hash = $jc(_$hash, tenantSlug.hashCode);
    _$hash = $jc(_$hash, tenantStatus.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlatformUserMembership')
          ..add('tenantId', tenantId)
          ..add('tenantName', tenantName)
          ..add('tenantSlug', tenantSlug)
          ..add('tenantStatus', tenantStatus)
          ..add('personId', personId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('roles', roles)
          ..add('active', active))
        .toString();
  }
}

class PlatformUserMembershipBuilder
    implements Builder<PlatformUserMembership, PlatformUserMembershipBuilder> {
  _$PlatformUserMembership? _$v;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  String? _tenantName;
  String? get tenantName => _$this._tenantName;
  set tenantName(String? tenantName) => _$this._tenantName = tenantName;

  String? _tenantSlug;
  String? get tenantSlug => _$this._tenantSlug;
  set tenantSlug(String? tenantSlug) => _$this._tenantSlug = tenantSlug;

  TenantStatus? _tenantStatus;
  TenantStatus? get tenantStatus => _$this._tenantStatus;
  set tenantStatus(TenantStatus? tenantStatus) =>
      _$this._tenantStatus = tenantStatus;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  SetBuilder<TenantRole>? _roles;
  SetBuilder<TenantRole> get roles =>
      _$this._roles ??= SetBuilder<TenantRole>();
  set roles(SetBuilder<TenantRole>? roles) => _$this._roles = roles;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  PlatformUserMembershipBuilder() {
    PlatformUserMembership._defaults(this);
  }

  PlatformUserMembershipBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenantId = $v.tenantId;
      _tenantName = $v.tenantName;
      _tenantSlug = $v.tenantSlug;
      _tenantStatus = $v.tenantStatus;
      _personId = $v.personId;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _roles = $v.roles.toBuilder();
      _active = $v.active;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformUserMembership other) {
    _$v = other as _$PlatformUserMembership;
  }

  @override
  void update(void Function(PlatformUserMembershipBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformUserMembership build() => _build();

  _$PlatformUserMembership _build() {
    _$PlatformUserMembership _$result;
    try {
      _$result = _$v ??
          _$PlatformUserMembership._(
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'PlatformUserMembership', 'tenantId'),
            tenantName: BuiltValueNullFieldError.checkNotNull(
                tenantName, r'PlatformUserMembership', 'tenantName'),
            tenantSlug: BuiltValueNullFieldError.checkNotNull(
                tenantSlug, r'PlatformUserMembership', 'tenantSlug'),
            tenantStatus: BuiltValueNullFieldError.checkNotNull(
                tenantStatus, r'PlatformUserMembership', 'tenantStatus'),
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'PlatformUserMembership', 'personId'),
            givenName: BuiltValueNullFieldError.checkNotNull(
                givenName, r'PlatformUserMembership', 'givenName'),
            familyName: BuiltValueNullFieldError.checkNotNull(
                familyName, r'PlatformUserMembership', 'familyName'),
            roles: roles.build(),
            active: BuiltValueNullFieldError.checkNotNull(
                active, r'PlatformUserMembership', 'active'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlatformUserMembership', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
