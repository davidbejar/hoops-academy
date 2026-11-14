// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Membership extends Membership {
  @override
  final TenantSummary tenant;
  @override
  final String personId;
  @override
  final String? givenName;
  @override
  final String? familyName;
  @override
  final BuiltSet<TenantRole> roles;
  @override
  final AuthzSummary authz;

  factory _$Membership([void Function(MembershipBuilder)? updates]) =>
      (MembershipBuilder()..update(updates))._build();

  _$Membership._(
      {required this.tenant,
      required this.personId,
      this.givenName,
      this.familyName,
      required this.roles,
      required this.authz})
      : super._();
  @override
  Membership rebuild(void Function(MembershipBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MembershipBuilder toBuilder() => MembershipBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Membership &&
        tenant == other.tenant &&
        personId == other.personId &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        roles == other.roles &&
        authz == other.authz;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenant.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jc(_$hash, authz.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Membership')
          ..add('tenant', tenant)
          ..add('personId', personId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('roles', roles)
          ..add('authz', authz))
        .toString();
  }
}

class MembershipBuilder implements Builder<Membership, MembershipBuilder> {
  _$Membership? _$v;

  TenantSummaryBuilder? _tenant;
  TenantSummaryBuilder get tenant => _$this._tenant ??= TenantSummaryBuilder();
  set tenant(TenantSummaryBuilder? tenant) => _$this._tenant = tenant;

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

  AuthzSummaryBuilder? _authz;
  AuthzSummaryBuilder get authz => _$this._authz ??= AuthzSummaryBuilder();
  set authz(AuthzSummaryBuilder? authz) => _$this._authz = authz;

  MembershipBuilder() {
    Membership._defaults(this);
  }

  MembershipBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenant = $v.tenant.toBuilder();
      _personId = $v.personId;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _roles = $v.roles.toBuilder();
      _authz = $v.authz.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Membership other) {
    _$v = other as _$Membership;
  }

  @override
  void update(void Function(MembershipBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Membership build() => _build();

  _$Membership _build() {
    _$Membership _$result;
    try {
      _$result = _$v ??
          _$Membership._(
            tenant: tenant.build(),
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'Membership', 'personId'),
            givenName: givenName,
            familyName: familyName,
            roles: roles.build(),
            authz: authz.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'tenant';
        tenant.build();

        _$failedField = 'roles';
        roles.build();
        _$failedField = 'authz';
        authz.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Membership', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
