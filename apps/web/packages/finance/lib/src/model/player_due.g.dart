// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_due.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerDue extends PlayerDue {
  @override
  final String id;
  @override
  final String feePlanName;
  @override
  final String period;
  @override
  final Date periodStart;
  @override
  final Date periodEnd;
  @override
  final int amountMinor;
  @override
  final String currency;
  @override
  final DueStatus status;
  @override
  final Date? paidOn;
  @override
  final PaymentMethod? paymentMethod;

  factory _$PlayerDue([void Function(PlayerDueBuilder)? updates]) =>
      (PlayerDueBuilder()..update(updates))._build();

  _$PlayerDue._(
      {required this.id,
      required this.feePlanName,
      required this.period,
      required this.periodStart,
      required this.periodEnd,
      required this.amountMinor,
      required this.currency,
      required this.status,
      this.paidOn,
      this.paymentMethod})
      : super._();
  @override
  PlayerDue rebuild(void Function(PlayerDueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerDueBuilder toBuilder() => PlayerDueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerDue &&
        id == other.id &&
        feePlanName == other.feePlanName &&
        period == other.period &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        amountMinor == other.amountMinor &&
        currency == other.currency &&
        status == other.status &&
        paidOn == other.paidOn &&
        paymentMethod == other.paymentMethod;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, feePlanName.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, paidOn.hashCode);
    _$hash = $jc(_$hash, paymentMethod.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerDue')
          ..add('id', id)
          ..add('feePlanName', feePlanName)
          ..add('period', period)
          ..add('periodStart', periodStart)
          ..add('periodEnd', periodEnd)
          ..add('amountMinor', amountMinor)
          ..add('currency', currency)
          ..add('status', status)
          ..add('paidOn', paidOn)
          ..add('paymentMethod', paymentMethod))
        .toString();
  }
}

class PlayerDueBuilder implements Builder<PlayerDue, PlayerDueBuilder> {
  _$PlayerDue? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _feePlanName;
  String? get feePlanName => _$this._feePlanName;
  set feePlanName(String? feePlanName) => _$this._feePlanName = feePlanName;

  String? _period;
  String? get period => _$this._period;
  set period(String? period) => _$this._period = period;

  Date? _periodStart;
  Date? get periodStart => _$this._periodStart;
  set periodStart(Date? periodStart) => _$this._periodStart = periodStart;

  Date? _periodEnd;
  Date? get periodEnd => _$this._periodEnd;
  set periodEnd(Date? periodEnd) => _$this._periodEnd = periodEnd;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  DueStatus? _status;
  DueStatus? get status => _$this._status;
  set status(DueStatus? status) => _$this._status = status;

  Date? _paidOn;
  Date? get paidOn => _$this._paidOn;
  set paidOn(Date? paidOn) => _$this._paidOn = paidOn;

  PaymentMethod? _paymentMethod;
  PaymentMethod? get paymentMethod => _$this._paymentMethod;
  set paymentMethod(PaymentMethod? paymentMethod) =>
      _$this._paymentMethod = paymentMethod;

  PlayerDueBuilder() {
    PlayerDue._defaults(this);
  }

  PlayerDueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _feePlanName = $v.feePlanName;
      _period = $v.period;
      _periodStart = $v.periodStart;
      _periodEnd = $v.periodEnd;
      _amountMinor = $v.amountMinor;
      _currency = $v.currency;
      _status = $v.status;
      _paidOn = $v.paidOn;
      _paymentMethod = $v.paymentMethod;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerDue other) {
    _$v = other as _$PlayerDue;
  }

  @override
  void update(void Function(PlayerDueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerDue build() => _build();

  _$PlayerDue _build() {
    final _$result = _$v ??
        _$PlayerDue._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PlayerDue', 'id'),
          feePlanName: BuiltValueNullFieldError.checkNotNull(
              feePlanName, r'PlayerDue', 'feePlanName'),
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'PlayerDue', 'period'),
          periodStart: BuiltValueNullFieldError.checkNotNull(
              periodStart, r'PlayerDue', 'periodStart'),
          periodEnd: BuiltValueNullFieldError.checkNotNull(
              periodEnd, r'PlayerDue', 'periodEnd'),
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'PlayerDue', 'amountMinor'),
          currency: BuiltValueNullFieldError.checkNotNull(
              currency, r'PlayerDue', 'currency'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PlayerDue', 'status'),
          paidOn: paidOn,
          paymentMethod: paymentMethod,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
