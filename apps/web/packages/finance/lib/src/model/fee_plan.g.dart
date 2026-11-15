// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FeePlan extends FeePlan {
  @override
  final String id;
  @override
  final String name;
  @override
  final String seasonId;
  @override
  final String? teamId;
  @override
  final String? ageCategoryId;
  @override
  final int amountMinor;
  @override
  final String currency;
  @override
  final FeeCadence cadence;
  @override
  final String? firstPeriod;
  @override
  final String? lastPeriod;
  @override
  final bool autoGenerate;
  @override
  final bool archived;
  @override
  final bool hasDues;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$FeePlan([void Function(FeePlanBuilder)? updates]) =>
      (FeePlanBuilder()..update(updates))._build();

  _$FeePlan._(
      {required this.id,
      required this.name,
      required this.seasonId,
      this.teamId,
      this.ageCategoryId,
      required this.amountMinor,
      required this.currency,
      required this.cadence,
      this.firstPeriod,
      this.lastPeriod,
      required this.autoGenerate,
      required this.archived,
      required this.hasDues,
      required this.createdAt,
      required this.updatedAt})
      : super._();
  @override
  FeePlan rebuild(void Function(FeePlanBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FeePlanBuilder toBuilder() => FeePlanBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FeePlan &&
        id == other.id &&
        name == other.name &&
        seasonId == other.seasonId &&
        teamId == other.teamId &&
        ageCategoryId == other.ageCategoryId &&
        amountMinor == other.amountMinor &&
        currency == other.currency &&
        cadence == other.cadence &&
        firstPeriod == other.firstPeriod &&
        lastPeriod == other.lastPeriod &&
        autoGenerate == other.autoGenerate &&
        archived == other.archived &&
        hasDues == other.hasDues &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, ageCategoryId.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, cadence.hashCode);
    _$hash = $jc(_$hash, firstPeriod.hashCode);
    _$hash = $jc(_$hash, lastPeriod.hashCode);
    _$hash = $jc(_$hash, autoGenerate.hashCode);
    _$hash = $jc(_$hash, archived.hashCode);
    _$hash = $jc(_$hash, hasDues.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FeePlan')
          ..add('id', id)
          ..add('name', name)
          ..add('seasonId', seasonId)
          ..add('teamId', teamId)
          ..add('ageCategoryId', ageCategoryId)
          ..add('amountMinor', amountMinor)
          ..add('currency', currency)
          ..add('cadence', cadence)
          ..add('firstPeriod', firstPeriod)
          ..add('lastPeriod', lastPeriod)
          ..add('autoGenerate', autoGenerate)
          ..add('archived', archived)
          ..add('hasDues', hasDues)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class FeePlanBuilder implements Builder<FeePlan, FeePlanBuilder> {
  _$FeePlan? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _ageCategoryId;
  String? get ageCategoryId => _$this._ageCategoryId;
  set ageCategoryId(String? ageCategoryId) =>
      _$this._ageCategoryId = ageCategoryId;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  FeeCadence? _cadence;
  FeeCadence? get cadence => _$this._cadence;
  set cadence(FeeCadence? cadence) => _$this._cadence = cadence;

  String? _firstPeriod;
  String? get firstPeriod => _$this._firstPeriod;
  set firstPeriod(String? firstPeriod) => _$this._firstPeriod = firstPeriod;

  String? _lastPeriod;
  String? get lastPeriod => _$this._lastPeriod;
  set lastPeriod(String? lastPeriod) => _$this._lastPeriod = lastPeriod;

  bool? _autoGenerate;
  bool? get autoGenerate => _$this._autoGenerate;
  set autoGenerate(bool? autoGenerate) => _$this._autoGenerate = autoGenerate;

  bool? _archived;
  bool? get archived => _$this._archived;
  set archived(bool? archived) => _$this._archived = archived;

  bool? _hasDues;
  bool? get hasDues => _$this._hasDues;
  set hasDues(bool? hasDues) => _$this._hasDues = hasDues;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  FeePlanBuilder() {
    FeePlan._defaults(this);
  }

  FeePlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _seasonId = $v.seasonId;
      _teamId = $v.teamId;
      _ageCategoryId = $v.ageCategoryId;
      _amountMinor = $v.amountMinor;
      _currency = $v.currency;
      _cadence = $v.cadence;
      _firstPeriod = $v.firstPeriod;
      _lastPeriod = $v.lastPeriod;
      _autoGenerate = $v.autoGenerate;
      _archived = $v.archived;
      _hasDues = $v.hasDues;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FeePlan other) {
    _$v = other as _$FeePlan;
  }

  @override
  void update(void Function(FeePlanBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FeePlan build() => _build();

  _$FeePlan _build() {
    final _$result = _$v ??
        _$FeePlan._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'FeePlan', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'FeePlan', 'name'),
          seasonId: BuiltValueNullFieldError.checkNotNull(
              seasonId, r'FeePlan', 'seasonId'),
          teamId: teamId,
          ageCategoryId: ageCategoryId,
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'FeePlan', 'amountMinor'),
          currency: BuiltValueNullFieldError.checkNotNull(
              currency, r'FeePlan', 'currency'),
          cadence: BuiltValueNullFieldError.checkNotNull(
              cadence, r'FeePlan', 'cadence'),
          firstPeriod: firstPeriod,
          lastPeriod: lastPeriod,
          autoGenerate: BuiltValueNullFieldError.checkNotNull(
              autoGenerate, r'FeePlan', 'autoGenerate'),
          archived: BuiltValueNullFieldError.checkNotNull(
              archived, r'FeePlan', 'archived'),
          hasDues: BuiltValueNullFieldError.checkNotNull(
              hasDues, r'FeePlan', 'hasDues'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'FeePlan', 'createdAt'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'FeePlan', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
