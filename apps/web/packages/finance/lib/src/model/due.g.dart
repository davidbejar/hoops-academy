// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Due extends Due {
  @override
  final String id;
  @override
  final String feePlanId;
  @override
  final String feePlanName;
  @override
  final String playerId;
  @override
  final String playerName;
  @override
  final String teamId;
  @override
  final String period;
  @override
  final Date periodStart;
  @override
  final Date periodEnd;
  @override
  final int amountMinor;
  @override
  final int planAmountMinor;
  @override
  final String currency;
  @override
  final DueStatus status;
  @override
  final String? reason;
  @override
  final Payment? payment;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Due([void Function(DueBuilder)? updates]) =>
      (DueBuilder()..update(updates))._build();

  _$Due._(
      {required this.id,
      required this.feePlanId,
      required this.feePlanName,
      required this.playerId,
      required this.playerName,
      required this.teamId,
      required this.period,
      required this.periodStart,
      required this.periodEnd,
      required this.amountMinor,
      required this.planAmountMinor,
      required this.currency,
      required this.status,
      this.reason,
      this.payment,
      required this.createdAt,
      required this.updatedAt})
      : super._();
  @override
  Due rebuild(void Function(DueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DueBuilder toBuilder() => DueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Due &&
        id == other.id &&
        feePlanId == other.feePlanId &&
        feePlanName == other.feePlanName &&
        playerId == other.playerId &&
        playerName == other.playerName &&
        teamId == other.teamId &&
        period == other.period &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        amountMinor == other.amountMinor &&
        planAmountMinor == other.planAmountMinor &&
        currency == other.currency &&
        status == other.status &&
        reason == other.reason &&
        payment == other.payment &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, feePlanId.hashCode);
    _$hash = $jc(_$hash, feePlanName.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, playerName.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, planAmountMinor.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, payment.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Due')
          ..add('id', id)
          ..add('feePlanId', feePlanId)
          ..add('feePlanName', feePlanName)
          ..add('playerId', playerId)
          ..add('playerName', playerName)
          ..add('teamId', teamId)
          ..add('period', period)
          ..add('periodStart', periodStart)
          ..add('periodEnd', periodEnd)
          ..add('amountMinor', amountMinor)
          ..add('planAmountMinor', planAmountMinor)
          ..add('currency', currency)
          ..add('status', status)
          ..add('reason', reason)
          ..add('payment', payment)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class DueBuilder implements Builder<Due, DueBuilder> {
  _$Due? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _feePlanId;
  String? get feePlanId => _$this._feePlanId;
  set feePlanId(String? feePlanId) => _$this._feePlanId = feePlanId;

  String? _feePlanName;
  String? get feePlanName => _$this._feePlanName;
  set feePlanName(String? feePlanName) => _$this._feePlanName = feePlanName;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _playerName;
  String? get playerName => _$this._playerName;
  set playerName(String? playerName) => _$this._playerName = playerName;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

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

  int? _planAmountMinor;
  int? get planAmountMinor => _$this._planAmountMinor;
  set planAmountMinor(int? planAmountMinor) =>
      _$this._planAmountMinor = planAmountMinor;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  DueStatus? _status;
  DueStatus? get status => _$this._status;
  set status(DueStatus? status) => _$this._status = status;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  PaymentBuilder? _payment;
  PaymentBuilder get payment => _$this._payment ??= PaymentBuilder();
  set payment(PaymentBuilder? payment) => _$this._payment = payment;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DueBuilder() {
    Due._defaults(this);
  }

  DueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _feePlanId = $v.feePlanId;
      _feePlanName = $v.feePlanName;
      _playerId = $v.playerId;
      _playerName = $v.playerName;
      _teamId = $v.teamId;
      _period = $v.period;
      _periodStart = $v.periodStart;
      _periodEnd = $v.periodEnd;
      _amountMinor = $v.amountMinor;
      _planAmountMinor = $v.planAmountMinor;
      _currency = $v.currency;
      _status = $v.status;
      _reason = $v.reason;
      _payment = $v.payment?.toBuilder();
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Due other) {
    _$v = other as _$Due;
  }

  @override
  void update(void Function(DueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Due build() => _build();

  _$Due _build() {
    _$Due _$result;
    try {
      _$result = _$v ??
          _$Due._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Due', 'id'),
            feePlanId: BuiltValueNullFieldError.checkNotNull(
                feePlanId, r'Due', 'feePlanId'),
            feePlanName: BuiltValueNullFieldError.checkNotNull(
                feePlanName, r'Due', 'feePlanName'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'Due', 'playerId'),
            playerName: BuiltValueNullFieldError.checkNotNull(
                playerName, r'Due', 'playerName'),
            teamId:
                BuiltValueNullFieldError.checkNotNull(teamId, r'Due', 'teamId'),
            period:
                BuiltValueNullFieldError.checkNotNull(period, r'Due', 'period'),
            periodStart: BuiltValueNullFieldError.checkNotNull(
                periodStart, r'Due', 'periodStart'),
            periodEnd: BuiltValueNullFieldError.checkNotNull(
                periodEnd, r'Due', 'periodEnd'),
            amountMinor: BuiltValueNullFieldError.checkNotNull(
                amountMinor, r'Due', 'amountMinor'),
            planAmountMinor: BuiltValueNullFieldError.checkNotNull(
                planAmountMinor, r'Due', 'planAmountMinor'),
            currency: BuiltValueNullFieldError.checkNotNull(
                currency, r'Due', 'currency'),
            status:
                BuiltValueNullFieldError.checkNotNull(status, r'Due', 'status'),
            reason: reason,
            payment: _payment?.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'Due', 'createdAt'),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
                updatedAt, r'Due', 'updatedAt'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payment';
        _payment?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Due', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
