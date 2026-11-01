// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authz_context.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuthzContext extends AuthzContext {
  @override
  final String sub;
  @override
  final String personId;
  @override
  final String tenantId;
  @override
  final TenantStatus tenantStatus;
  @override
  final BuiltSet<TenantRole> roles;
  @override
  final BuiltList<String> staffTeamIds;
  @override
  final BuiltList<String> linkedPlayerIds;
  @override
  final String? ownPlayerId;

  factory _$AuthzContext([void Function(AuthzContextBuilder)? updates]) =>
      (AuthzContextBuilder()..update(updates))._build();

  _$AuthzContext._(
      {required this.sub,
      required this.personId,
      required this.tenantId,
      required this.tenantStatus,
      required this.roles,
      required this.staffTeamIds,
      required this.linkedPlayerIds,
      this.ownPlayerId})
      : super._();
  @override
  AuthzContext rebuild(void Function(AuthzContextBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuthzContextBuilder toBuilder() => AuthzContextBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuthzContext &&
        sub == other.sub &&
        personId == other.personId &&
        tenantId == other.tenantId &&
        tenantStatus == other.tenantStatus &&
        roles == other.roles &&
        staffTeamIds == other.staffTeamIds &&
        linkedPlayerIds == other.linkedPlayerIds &&
        ownPlayerId == other.ownPlayerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, sub.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, tenantStatus.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jc(_$hash, staffTeamIds.hashCode);
    _$hash = $jc(_$hash, linkedPlayerIds.hashCode);
    _$hash = $jc(_$hash, ownPlayerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuthzContext')
          ..add('sub', sub)
          ..add('personId', personId)
          ..add('tenantId', tenantId)
          ..add('tenantStatus', tenantStatus)
          ..add('roles', roles)
          ..add('staffTeamIds', staffTeamIds)
          ..add('linkedPlayerIds', linkedPlayerIds)
          ..add('ownPlayerId', ownPlayerId))
        .toString();
  }
}

class AuthzContextBuilder
    implements Builder<AuthzContext, AuthzContextBuilder> {
  _$AuthzContext? _$v;

  String? _sub;
  String? get sub => _$this._sub;
  set sub(String? sub) => _$this._sub = sub;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  TenantStatus? _tenantStatus;
  TenantStatus? get tenantStatus => _$this._tenantStatus;
  set tenantStatus(TenantStatus? tenantStatus) =>
      _$this._tenantStatus = tenantStatus;

  SetBuilder<TenantRole>? _roles;
  SetBuilder<TenantRole> get roles =>
      _$this._roles ??= SetBuilder<TenantRole>();
  set roles(SetBuilder<TenantRole>? roles) => _$this._roles = roles;

  ListBuilder<String>? _staffTeamIds;
  ListBuilder<String> get staffTeamIds =>
      _$this._staffTeamIds ??= ListBuilder<String>();
  set staffTeamIds(ListBuilder<String>? staffTeamIds) =>
      _$this._staffTeamIds = staffTeamIds;

  ListBuilder<String>? _linkedPlayerIds;
  ListBuilder<String> get linkedPlayerIds =>
      _$this._linkedPlayerIds ??= ListBuilder<String>();
  set linkedPlayerIds(ListBuilder<String>? linkedPlayerIds) =>
      _$this._linkedPlayerIds = linkedPlayerIds;

  String? _ownPlayerId;
  String? get ownPlayerId => _$this._ownPlayerId;
  set ownPlayerId(String? ownPlayerId) => _$this._ownPlayerId = ownPlayerId;

  AuthzContextBuilder() {
    AuthzContext._defaults(this);
  }

  AuthzContextBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _sub = $v.sub;
      _personId = $v.personId;
      _tenantId = $v.tenantId;
      _tenantStatus = $v.tenantStatus;
      _roles = $v.roles.toBuilder();
      _staffTeamIds = $v.staffTeamIds.toBuilder();
      _linkedPlayerIds = $v.linkedPlayerIds.toBuilder();
      _ownPlayerId = $v.ownPlayerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuthzContext other) {
    _$v = other as _$AuthzContext;
  }

  @override
  void update(void Function(AuthzContextBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuthzContext build() => _build();

  _$AuthzContext _build() {
    _$AuthzContext _$result;
    try {
      _$result = _$v ??
          _$AuthzContext._(
            sub: BuiltValueNullFieldError.checkNotNull(
                sub, r'AuthzContext', 'sub'),
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'AuthzContext', 'personId'),
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'AuthzContext', 'tenantId'),
            tenantStatus: BuiltValueNullFieldError.checkNotNull(
                tenantStatus, r'AuthzContext', 'tenantStatus'),
            roles: roles.build(),
            staffTeamIds: staffTeamIds.build(),
            linkedPlayerIds: linkedPlayerIds.build(),
            ownPlayerId: ownPlayerId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
        _$failedField = 'staffTeamIds';
        staffTeamIds.build();
        _$failedField = 'linkedPlayerIds';
        linkedPlayerIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AuthzContext', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
