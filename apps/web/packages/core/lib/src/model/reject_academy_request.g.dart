// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reject_academy_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RejectAcademyRequest extends RejectAcademyRequest {
  @override
  final String reason;

  factory _$RejectAcademyRequest(
          [void Function(RejectAcademyRequestBuilder)? updates]) =>
      (RejectAcademyRequestBuilder()..update(updates))._build();

  _$RejectAcademyRequest._({required this.reason}) : super._();
  @override
  RejectAcademyRequest rebuild(
          void Function(RejectAcademyRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RejectAcademyRequestBuilder toBuilder() =>
      RejectAcademyRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RejectAcademyRequest && reason == other.reason;
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
    return (newBuiltValueToStringHelper(r'RejectAcademyRequest')
          ..add('reason', reason))
        .toString();
  }
}

class RejectAcademyRequestBuilder
    implements Builder<RejectAcademyRequest, RejectAcademyRequestBuilder> {
  _$RejectAcademyRequest? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  RejectAcademyRequestBuilder() {
    RejectAcademyRequest._defaults(this);
  }

  RejectAcademyRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RejectAcademyRequest other) {
    _$v = other as _$RejectAcademyRequest;
  }

  @override
  void update(void Function(RejectAcademyRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RejectAcademyRequest build() => _build();

  _$RejectAcademyRequest _build() {
    final _$result = _$v ??
        _$RejectAcademyRequest._(
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'RejectAcademyRequest', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
