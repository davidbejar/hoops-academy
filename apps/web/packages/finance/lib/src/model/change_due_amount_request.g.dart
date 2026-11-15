// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_due_amount_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChangeDueAmountRequest extends ChangeDueAmountRequest {
  @override
  final int amountMinor;
  @override
  final String reason;

  factory _$ChangeDueAmountRequest(
          [void Function(ChangeDueAmountRequestBuilder)? updates]) =>
      (ChangeDueAmountRequestBuilder()..update(updates))._build();

  _$ChangeDueAmountRequest._({required this.amountMinor, required this.reason})
      : super._();
  @override
  ChangeDueAmountRequest rebuild(
          void Function(ChangeDueAmountRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChangeDueAmountRequestBuilder toBuilder() =>
      ChangeDueAmountRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChangeDueAmountRequest &&
        amountMinor == other.amountMinor &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChangeDueAmountRequest')
          ..add('amountMinor', amountMinor)
          ..add('reason', reason))
        .toString();
  }
}

class ChangeDueAmountRequestBuilder
    implements Builder<ChangeDueAmountRequest, ChangeDueAmountRequestBuilder> {
  _$ChangeDueAmountRequest? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  ChangeDueAmountRequestBuilder() {
    ChangeDueAmountRequest._defaults(this);
  }

  ChangeDueAmountRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChangeDueAmountRequest other) {
    _$v = other as _$ChangeDueAmountRequest;
  }

  @override
  void update(void Function(ChangeDueAmountRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChangeDueAmountRequest build() => _build();

  _$ChangeDueAmountRequest _build() {
    final _$result = _$v ??
        _$ChangeDueAmountRequest._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'ChangeDueAmountRequest', 'amountMinor'),
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'ChangeDueAmountRequest', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
