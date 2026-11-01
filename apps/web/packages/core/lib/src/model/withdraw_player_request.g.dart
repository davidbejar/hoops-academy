// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdraw_player_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WithdrawPlayerRequest extends WithdrawPlayerRequest {
  @override
  final String? reason;

  factory _$WithdrawPlayerRequest(
          [void Function(WithdrawPlayerRequestBuilder)? updates]) =>
      (WithdrawPlayerRequestBuilder()..update(updates))._build();

  _$WithdrawPlayerRequest._({this.reason}) : super._();
  @override
  WithdrawPlayerRequest rebuild(
          void Function(WithdrawPlayerRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WithdrawPlayerRequestBuilder toBuilder() =>
      WithdrawPlayerRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WithdrawPlayerRequest && reason == other.reason;
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
    return (newBuiltValueToStringHelper(r'WithdrawPlayerRequest')
          ..add('reason', reason))
        .toString();
  }
}

class WithdrawPlayerRequestBuilder
    implements Builder<WithdrawPlayerRequest, WithdrawPlayerRequestBuilder> {
  _$WithdrawPlayerRequest? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  WithdrawPlayerRequestBuilder() {
    WithdrawPlayerRequest._defaults(this);
  }

  WithdrawPlayerRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WithdrawPlayerRequest other) {
    _$v = other as _$WithdrawPlayerRequest;
  }

  @override
  void update(void Function(WithdrawPlayerRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WithdrawPlayerRequest build() => _build();

  _$WithdrawPlayerRequest _build() {
    final _$result = _$v ??
        _$WithdrawPlayerRequest._(
          reason: reason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
