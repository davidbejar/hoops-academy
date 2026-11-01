// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replace_member_roles_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReplaceMemberRolesRequest extends ReplaceMemberRolesRequest {
  @override
  final BuiltSet<TenantRole> roles;

  factory _$ReplaceMemberRolesRequest(
          [void Function(ReplaceMemberRolesRequestBuilder)? updates]) =>
      (ReplaceMemberRolesRequestBuilder()..update(updates))._build();

  _$ReplaceMemberRolesRequest._({required this.roles}) : super._();
  @override
  ReplaceMemberRolesRequest rebuild(
          void Function(ReplaceMemberRolesRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReplaceMemberRolesRequestBuilder toBuilder() =>
      ReplaceMemberRolesRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReplaceMemberRolesRequest && roles == other.roles;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReplaceMemberRolesRequest')
          ..add('roles', roles))
        .toString();
  }
}

class ReplaceMemberRolesRequestBuilder
    implements
        Builder<ReplaceMemberRolesRequest, ReplaceMemberRolesRequestBuilder> {
  _$ReplaceMemberRolesRequest? _$v;

  SetBuilder<TenantRole>? _roles;
  SetBuilder<TenantRole> get roles =>
      _$this._roles ??= SetBuilder<TenantRole>();
  set roles(SetBuilder<TenantRole>? roles) => _$this._roles = roles;

  ReplaceMemberRolesRequestBuilder() {
    ReplaceMemberRolesRequest._defaults(this);
  }

  ReplaceMemberRolesRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _roles = $v.roles.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReplaceMemberRolesRequest other) {
    _$v = other as _$ReplaceMemberRolesRequest;
  }

  @override
  void update(void Function(ReplaceMemberRolesRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReplaceMemberRolesRequest build() => _build();

  _$ReplaceMemberRolesRequest _build() {
    _$ReplaceMemberRolesRequest _$result;
    try {
      _$result = _$v ??
          _$ReplaceMemberRolesRequest._(
            roles: roles.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ReplaceMemberRolesRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
