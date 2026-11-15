// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_fee_plan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateFeePlanRequest extends CreateFeePlanRequest {
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
  final FeeCadence cadence;
  @override
  final String? firstPeriod;
  @override
  final String? lastPeriod;
  @override
  final bool? autoGenerate;

  factory _$CreateFeePlanRequest(
          [void Function(CreateFeePlanRequestBuilder)? updates]) =>
      (CreateFeePlanRequestBuilder()..update(updates))._build();

  _$CreateFeePlanRequest._(
      {required this.name,
      required this.seasonId,
      this.teamId,
      this.ageCategoryId,
      required this.amountMinor,
      required this.cadence,
      this.firstPeriod,
      this.lastPeriod,
      this.autoGenerate})
      : super._();
  @override
  CreateFeePlanRequest rebuild(
          void Function(CreateFeePlanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateFeePlanRequestBuilder toBuilder() =>
      CreateFeePlanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateFeePlanRequest &&
        name == other.name &&
        seasonId == other.seasonId &&
        teamId == other.teamId &&
        ageCategoryId == other.ageCategoryId &&
        amountMinor == other.amountMinor &&
        cadence == other.cadence &&
        firstPeriod == other.firstPeriod &&
        lastPeriod == other.lastPeriod &&
        autoGenerate == other.autoGenerate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, ageCategoryId.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, cadence.hashCode);
    _$hash = $jc(_$hash, firstPeriod.hashCode);
    _$hash = $jc(_$hash, lastPeriod.hashCode);
    _$hash = $jc(_$hash, autoGenerate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateFeePlanRequest')
          ..add('name', name)
          ..add('seasonId', seasonId)
          ..add('teamId', teamId)
          ..add('ageCategoryId', ageCategoryId)
          ..add('amountMinor', amountMinor)
          ..add('cadence', cadence)
          ..add('firstPeriod', firstPeriod)
          ..add('lastPeriod', lastPeriod)
          ..add('autoGenerate', autoGenerate))
        .toString();
  }
}

class CreateFeePlanRequestBuilder
    implements Builder<CreateFeePlanRequest, CreateFeePlanRequestBuilder> {
  _$CreateFeePlanRequest? _$v;

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

  CreateFeePlanRequestBuilder() {
    CreateFeePlanRequest._defaults(this);
  }

  CreateFeePlanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _seasonId = $v.seasonId;
      _teamId = $v.teamId;
      _ageCategoryId = $v.ageCategoryId;
      _amountMinor = $v.amountMinor;
      _cadence = $v.cadence;
      _firstPeriod = $v.firstPeriod;
      _lastPeriod = $v.lastPeriod;
      _autoGenerate = $v.autoGenerate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateFeePlanRequest other) {
    _$v = other as _$CreateFeePlanRequest;
  }

  @override
  void update(void Function(CreateFeePlanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateFeePlanRequest build() => _build();

  _$CreateFeePlanRequest _build() {
    final _$result = _$v ??
        _$CreateFeePlanRequest._(
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'CreateFeePlanRequest', 'name'),
          seasonId: BuiltValueNullFieldError.checkNotNull(
              seasonId, r'CreateFeePlanRequest', 'seasonId'),
          teamId: teamId,
          ageCategoryId: ageCategoryId,
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'CreateFeePlanRequest', 'amountMinor'),
          cadence: BuiltValueNullFieldError.checkNotNull(
              cadence, r'CreateFeePlanRequest', 'cadence'),
          firstPeriod: firstPeriod,
          lastPeriod: lastPeriod,
          autoGenerate: autoGenerate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
