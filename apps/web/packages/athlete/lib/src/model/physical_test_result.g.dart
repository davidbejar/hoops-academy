// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestResult extends PhysicalTestResult {
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String id;
  @override
  final String playerId;
  @override
  final String testTypeId;
  @override
  final String testCode;
  @override
  final String unit;
  @override
  final Date measuredOn;
  @override
  final double value;
  @override
  final int? ageAtMeasurement;
  @override
  final BandStatus bandStatus;
  @override
  final NormBand? expectedBand;
  @override
  final String? normId;
  @override
  final bool referencePending;
  @override
  final String? notes;

  factory _$PhysicalTestResult(
          [void Function(PhysicalTestResultBuilder)? updates]) =>
      (PhysicalTestResultBuilder()..update(updates))._build();

  _$PhysicalTestResult._(
      {required this.recordedBy,
      required this.recordedAt,
      required this.id,
      required this.playerId,
      required this.testTypeId,
      required this.testCode,
      required this.unit,
      required this.measuredOn,
      required this.value,
      this.ageAtMeasurement,
      required this.bandStatus,
      this.expectedBand,
      this.normId,
      required this.referencePending,
      this.notes})
      : super._();
  @override
  PhysicalTestResult rebuild(
          void Function(PhysicalTestResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhysicalTestResultBuilder toBuilder() =>
      PhysicalTestResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhysicalTestResult &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        id == other.id &&
        playerId == other.playerId &&
        testTypeId == other.testTypeId &&
        testCode == other.testCode &&
        unit == other.unit &&
        measuredOn == other.measuredOn &&
        value == other.value &&
        ageAtMeasurement == other.ageAtMeasurement &&
        bandStatus == other.bandStatus &&
        expectedBand == other.expectedBand &&
        normId == other.normId &&
        referencePending == other.referencePending &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, testTypeId.hashCode);
    _$hash = $jc(_$hash, testCode.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jc(_$hash, ageAtMeasurement.hashCode);
    _$hash = $jc(_$hash, bandStatus.hashCode);
    _$hash = $jc(_$hash, expectedBand.hashCode);
    _$hash = $jc(_$hash, normId.hashCode);
    _$hash = $jc(_$hash, referencePending.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhysicalTestResult')
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('id', id)
          ..add('playerId', playerId)
          ..add('testTypeId', testTypeId)
          ..add('testCode', testCode)
          ..add('unit', unit)
          ..add('measuredOn', measuredOn)
          ..add('value', value)
          ..add('ageAtMeasurement', ageAtMeasurement)
          ..add('bandStatus', bandStatus)
          ..add('expectedBand', expectedBand)
          ..add('normId', normId)
          ..add('referencePending', referencePending)
          ..add('notes', notes))
        .toString();
  }
}

class PhysicalTestResultBuilder
    implements Builder<PhysicalTestResult, PhysicalTestResultBuilder> {
  _$PhysicalTestResult? _$v;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(DateTime? recordedAt) => _$this._recordedAt = recordedAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _testTypeId;
  String? get testTypeId => _$this._testTypeId;
  set testTypeId(String? testTypeId) => _$this._testTypeId = testTypeId;

  String? _testCode;
  String? get testCode => _$this._testCode;
  set testCode(String? testCode) => _$this._testCode = testCode;

  String? _unit;
  String? get unit => _$this._unit;
  set unit(String? unit) => _$this._unit = unit;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _value;
  double? get value => _$this._value;
  set value(double? value) => _$this._value = value;

  int? _ageAtMeasurement;
  int? get ageAtMeasurement => _$this._ageAtMeasurement;
  set ageAtMeasurement(int? ageAtMeasurement) =>
      _$this._ageAtMeasurement = ageAtMeasurement;

  BandStatus? _bandStatus;
  BandStatus? get bandStatus => _$this._bandStatus;
  set bandStatus(BandStatus? bandStatus) => _$this._bandStatus = bandStatus;

  NormBand? _expectedBand;
  NormBand? get expectedBand => _$this._expectedBand;
  set expectedBand(NormBand? expectedBand) =>
      _$this._expectedBand = expectedBand;

  String? _normId;
  String? get normId => _$this._normId;
  set normId(String? normId) => _$this._normId = normId;

  bool? _referencePending;
  bool? get referencePending => _$this._referencePending;
  set referencePending(bool? referencePending) =>
      _$this._referencePending = referencePending;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  PhysicalTestResultBuilder() {
    PhysicalTestResult._defaults(this);
  }

  PhysicalTestResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _id = $v.id;
      _playerId = $v.playerId;
      _testTypeId = $v.testTypeId;
      _testCode = $v.testCode;
      _unit = $v.unit;
      _measuredOn = $v.measuredOn;
      _value = $v.value;
      _ageAtMeasurement = $v.ageAtMeasurement;
      _bandStatus = $v.bandStatus;
      _expectedBand = $v.expectedBand;
      _normId = $v.normId;
      _referencePending = $v.referencePending;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhysicalTestResult other) {
    _$v = other as _$PhysicalTestResult;
  }

  @override
  void update(void Function(PhysicalTestResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhysicalTestResult build() => _build();

  _$PhysicalTestResult _build() {
    _$PhysicalTestResult _$result;
    try {
      _$result = _$v ??
          _$PhysicalTestResult._(
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PhysicalTestResult', 'recordedAt'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PhysicalTestResult', 'id'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PhysicalTestResult', 'playerId'),
            testTypeId: BuiltValueNullFieldError.checkNotNull(
                testTypeId, r'PhysicalTestResult', 'testTypeId'),
            testCode: BuiltValueNullFieldError.checkNotNull(
                testCode, r'PhysicalTestResult', 'testCode'),
            unit: BuiltValueNullFieldError.checkNotNull(
                unit, r'PhysicalTestResult', 'unit'),
            measuredOn: BuiltValueNullFieldError.checkNotNull(
                measuredOn, r'PhysicalTestResult', 'measuredOn'),
            value: BuiltValueNullFieldError.checkNotNull(
                value, r'PhysicalTestResult', 'value'),
            ageAtMeasurement: ageAtMeasurement,
            bandStatus: BuiltValueNullFieldError.checkNotNull(
                bandStatus, r'PhysicalTestResult', 'bandStatus'),
            expectedBand: expectedBand,
            normId: normId,
            referencePending: BuiltValueNullFieldError.checkNotNull(
                referencePending, r'PhysicalTestResult', 'referencePending'),
            notes: notes,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PhysicalTestResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
