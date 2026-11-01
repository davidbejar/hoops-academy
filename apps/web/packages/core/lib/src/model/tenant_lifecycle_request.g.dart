// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_lifecycle_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantLifecycleRequest extends TenantLifecycleRequest {
  @override
  final String reason;

  factory _$TenantLifecycleRequest(
          [void Function(TenantLifecycleRequestBuilder)? updates]) =>
      (TenantLifecycleRequestBuilder()..update(updates))._build();

  _$TenantLifecycleRequest._({required this.reason}) : super._();
  @override
  TenantLifecycleRequest rebuild(
          void Function(TenantLifecycleRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantLifecycleRequestBuilder toBuilder() =>
      TenantLifecycleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantLifecycleRequest && reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantLifecycleRequest')
          ..add('reason', reason))
        .toString();
  }
}

class TenantLifecycleRequestBuilder
    implements Builder<TenantLifecycleRequest, TenantLifecycleRequestBuilder> {
  _$TenantLifecycleRequest? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  TenantLifecycleRequestBuilder() {
    TenantLifecycleRequest._defaults(this);
  }

  TenantLifecycleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantLifecycleRequest other) {
    _$v = other as _$TenantLifecycleRequest;
  }

  @override
  void update(void Function(TenantLifecycleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantLifecycleRequest build() => _build();

  _$TenantLifecycleRequest _build() {
    final _$result = _$v ??
        _$TenantLifecycleRequest._(
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'TenantLifecycleRequest', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
