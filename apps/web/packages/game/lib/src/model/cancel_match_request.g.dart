// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_match_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CancelMatchRequest extends CancelMatchRequest {
  @override
  final String reason;

  factory _$CancelMatchRequest(
          [void Function(CancelMatchRequestBuilder)? updates]) =>
      (CancelMatchRequestBuilder()..update(updates))._build();

  _$CancelMatchRequest._({required this.reason}) : super._();
  @override
  CancelMatchRequest rebuild(
          void Function(CancelMatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CancelMatchRequestBuilder toBuilder() =>
      CancelMatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CancelMatchRequest && reason == other.reason;
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
    return (newBuiltValueToStringHelper(r'CancelMatchRequest')
          ..add('reason', reason))
        .toString();
  }
}

class CancelMatchRequestBuilder
    implements Builder<CancelMatchRequest, CancelMatchRequestBuilder> {
  _$CancelMatchRequest? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  CancelMatchRequestBuilder() {
    CancelMatchRequest._defaults(this);
  }

  CancelMatchRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CancelMatchRequest other) {
    _$v = other as _$CancelMatchRequest;
  }

  @override
  void update(void Function(CancelMatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CancelMatchRequest build() => _build();

  _$CancelMatchRequest _build() {
    final _$result = _$v ??
        _$CancelMatchRequest._(
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'CancelMatchRequest', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
