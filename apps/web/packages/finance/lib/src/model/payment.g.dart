// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Payment extends Payment {
  @override
  final String id;
  @override
  final String dueId;
  @override
  final int amountMinor;
  @override
  final Date paidOn;
  @override
  final PaymentMethod method;
  @override
  final String? note;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final bool voided;
  @override
  final DateTime? voidedAt;
  @override
  final String? voidReason;
  @override
  final PersonRef? voidedBy;

  factory _$Payment([void Function(PaymentBuilder)? updates]) =>
      (PaymentBuilder()..update(updates))._build();

  _$Payment._(
      {required this.id,
      required this.dueId,
      required this.amountMinor,
      required this.paidOn,
      required this.method,
      this.note,
      required this.recordedBy,
      required this.recordedAt,
      required this.voided,
      this.voidedAt,
      this.voidReason,
      this.voidedBy})
      : super._();
  @override
  Payment rebuild(void Function(PaymentBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentBuilder toBuilder() => PaymentBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Payment &&
        id == other.id &&
        dueId == other.dueId &&
        amountMinor == other.amountMinor &&
        paidOn == other.paidOn &&
        method == other.method &&
        note == other.note &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        voided == other.voided &&
        voidedAt == other.voidedAt &&
        voidReason == other.voidReason &&
        voidedBy == other.voidedBy;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, dueId.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, paidOn.hashCode);
    _$hash = $jc(_$hash, method.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, voided.hashCode);
    _$hash = $jc(_$hash, voidedAt.hashCode);
    _$hash = $jc(_$hash, voidReason.hashCode);
    _$hash = $jc(_$hash, voidedBy.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Payment')
          ..add('id', id)
          ..add('dueId', dueId)
          ..add('amountMinor', amountMinor)
          ..add('paidOn', paidOn)
          ..add('method', method)
          ..add('note', note)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('voided', voided)
          ..add('voidedAt', voidedAt)
          ..add('voidReason', voidReason)
          ..add('voidedBy', voidedBy))
        .toString();
  }
}

class PaymentBuilder implements Builder<Payment, PaymentBuilder> {
  _$Payment? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _dueId;
  String? get dueId => _$this._dueId;
  set dueId(String? dueId) => _$this._dueId = dueId;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  Date? _paidOn;
  Date? get paidOn => _$this._paidOn;
  set paidOn(Date? paidOn) => _$this._paidOn = paidOn;

  PaymentMethod? _method;
  PaymentMethod? get method => _$this._method;
  set method(PaymentMethod? method) => _$this._method = method;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(DateTime? recordedAt) => _$this._recordedAt = recordedAt;

  bool? _voided;
  bool? get voided => _$this._voided;
  set voided(bool? voided) => _$this._voided = voided;

  DateTime? _voidedAt;
  DateTime? get voidedAt => _$this._voidedAt;
  set voidedAt(DateTime? voidedAt) => _$this._voidedAt = voidedAt;

  String? _voidReason;
  String? get voidReason => _$this._voidReason;
  set voidReason(String? voidReason) => _$this._voidReason = voidReason;

  PersonRefBuilder? _voidedBy;
  PersonRefBuilder get voidedBy => _$this._voidedBy ??= PersonRefBuilder();
  set voidedBy(PersonRefBuilder? voidedBy) => _$this._voidedBy = voidedBy;

  PaymentBuilder() {
    Payment._defaults(this);
  }

  PaymentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _dueId = $v.dueId;
      _amountMinor = $v.amountMinor;
      _paidOn = $v.paidOn;
      _method = $v.method;
      _note = $v.note;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _voided = $v.voided;
      _voidedAt = $v.voidedAt;
      _voidReason = $v.voidReason;
      _voidedBy = $v.voidedBy?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Payment other) {
    _$v = other as _$Payment;
  }

  @override
  void update(void Function(PaymentBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Payment build() => _build();

  _$Payment _build() {
    _$Payment _$result;
    try {
      _$result = _$v ??
          _$Payment._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Payment', 'id'),
            dueId: BuiltValueNullFieldError.checkNotNull(
                dueId, r'Payment', 'dueId'),
            amountMinor: BuiltValueNullFieldError.checkNotNull(
                amountMinor, r'Payment', 'amountMinor'),
            paidOn: BuiltValueNullFieldError.checkNotNull(
                paidOn, r'Payment', 'paidOn'),
            method: BuiltValueNullFieldError.checkNotNull(
                method, r'Payment', 'method'),
            note: note,
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'Payment', 'recordedAt'),
            voided: BuiltValueNullFieldError.checkNotNull(
                voided, r'Payment', 'voided'),
            voidedAt: voidedAt,
            voidReason: voidReason,
            voidedBy: _voidedBy?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();

        _$failedField = 'voidedBy';
        _voidedBy?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Payment', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
