// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pay_due_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PayDueRequest extends PayDueRequest {
  @override
  final Date paidOn;
  @override
  final PaymentMethod method;
  @override
  final String? note;

  factory _$PayDueRequest([void Function(PayDueRequestBuilder)? updates]) =>
      (PayDueRequestBuilder()..update(updates))._build();

  _$PayDueRequest._({required this.paidOn, required this.method, this.note})
      : super._();
  @override
  PayDueRequest rebuild(void Function(PayDueRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PayDueRequestBuilder toBuilder() => PayDueRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PayDueRequest &&
        paidOn == other.paidOn &&
        method == other.method &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, paidOn.hashCode);
    _$hash = $jc(_$hash, method.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PayDueRequest')
          ..add('paidOn', paidOn)
          ..add('method', method)
          ..add('note', note))
        .toString();
  }
}

class PayDueRequestBuilder
    implements Builder<PayDueRequest, PayDueRequestBuilder> {
  _$PayDueRequest? _$v;

  Date? _paidOn;
  Date? get paidOn => _$this._paidOn;
  set paidOn(Date? paidOn) => _$this._paidOn = paidOn;

  PaymentMethod? _method;
  PaymentMethod? get method => _$this._method;
  set method(PaymentMethod? method) => _$this._method = method;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  PayDueRequestBuilder() {
    PayDueRequest._defaults(this);
  }

  PayDueRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _paidOn = $v.paidOn;
      _method = $v.method;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PayDueRequest other) {
    _$v = other as _$PayDueRequest;
  }

  @override
  void update(void Function(PayDueRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PayDueRequest build() => _build();

  _$PayDueRequest _build() {
    final _$result = _$v ??
        _$PayDueRequest._(
          paidOn: BuiltValueNullFieldError.checkNotNull(
              paidOn, r'PayDueRequest', 'paidOn'),
          method: BuiltValueNullFieldError.checkNotNull(
              method, r'PayDueRequest', 'method'),
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
