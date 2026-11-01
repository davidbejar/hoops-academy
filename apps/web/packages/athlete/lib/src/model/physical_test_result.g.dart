// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestResult extends PhysicalTestResult {
  @override
  final NormBand? expectedBand;
  @override
  final String? normId;
  @override
  final String testTypeId;
  @override
  final String testCode;
  @override
  final String unit;
  @override
  final String? notes;
  @override
  final Date measuredOn;
  @override
  final int ageAtMeasurement;
  @override
  final String id;
  @override
  final double value;
  @override
  final bool referencePending;
  @override
  final String playerId;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;

  factory _$PhysicalTestResult(
          [void Function(PhysicalTestResultBuilder)? updates]) =>
      (PhysicalTestResultBuilder()..update(updates))._build();

  _$PhysicalTestResult._(
      {this.expectedBand,
      this.normId,
      required this.testTypeId,
      required this.testCode,
      required this.unit,
      this.notes,
      required this.measuredOn,
      required this.ageAtMeasurement,
      required this.id,
      required this.value,
      required this.referencePending,
      required this.playerId,
      required this.recordedBy,
      required this.recordedAt})
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
        expectedBand == other.expectedBand &&
        normId == other.normId &&
        testTypeId == other.testTypeId &&
        testCode == other.testCode &&
        unit == other.unit &&
        notes == other.notes &&
        measuredOn == other.measuredOn &&
        ageAtMeasurement == other.ageAtMeasurement &&
        id == other.id &&
        value == other.value &&
        referencePending == other.referencePending &&
        playerId == other.playerId &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, expectedBand.hashCode);
    _$hash = $jc(_$hash, normId.hashCode);
    _$hash = $jc(_$hash, testTypeId.hashCode);
    _$hash = $jc(_$hash, testCode.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, ageAtMeasurement.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jc(_$hash, referencePending.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhysicalTestResult')
          ..add('expectedBand', expectedBand)
          ..add('normId', normId)
          ..add('testTypeId', testTypeId)
          ..add('testCode', testCode)
          ..add('unit', unit)
          ..add('notes', notes)
          ..add('measuredOn', measuredOn)
          ..add('ageAtMeasurement', ageAtMeasurement)
          ..add('id', id)
          ..add('value', value)
          ..add('referencePending', referencePending)
          ..add('playerId', playerId)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class PhysicalTestResultBuilder
    implements
        Builder<PhysicalTestResult, PhysicalTestResultBuilder>,
        AuditInfoBuilder {
  _$PhysicalTestResult? _$v;

  NormBand? _expectedBand;
  NormBand? get expectedBand => _$this._expectedBand;
  set expectedBand(covariant NormBand? expectedBand) =>
      _$this._expectedBand = expectedBand;

  String? _normId;
  String? get normId => _$this._normId;
  set normId(covariant String? normId) => _$this._normId = normId;

  String? _testTypeId;
  String? get testTypeId => _$this._testTypeId;
  set testTypeId(covariant String? testTypeId) =>
      _$this._testTypeId = testTypeId;

  String? _testCode;
  String? get testCode => _$this._testCode;
  set testCode(covariant String? testCode) => _$this._testCode = testCode;

  String? _unit;
  String? get unit => _$this._unit;
  set unit(covariant String? unit) => _$this._unit = unit;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(covariant String? notes) => _$this._notes = notes;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(covariant Date? measuredOn) => _$this._measuredOn = measuredOn;

  int? _ageAtMeasurement;
  int? get ageAtMeasurement => _$this._ageAtMeasurement;
  set ageAtMeasurement(covariant int? ageAtMeasurement) =>
      _$this._ageAtMeasurement = ageAtMeasurement;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  double? _value;
  double? get value => _$this._value;
  set value(covariant double? value) => _$this._value = value;

  bool? _referencePending;
  bool? get referencePending => _$this._referencePending;
  set referencePending(covariant bool? referencePending) =>
      _$this._referencePending = referencePending;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  PhysicalTestResultBuilder() {
    PhysicalTestResult._defaults(this);
  }

  PhysicalTestResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _expectedBand = $v.expectedBand;
      _normId = $v.normId;
      _testTypeId = $v.testTypeId;
      _testCode = $v.testCode;
      _unit = $v.unit;
      _notes = $v.notes;
      _measuredOn = $v.measuredOn;
      _ageAtMeasurement = $v.ageAtMeasurement;
      _id = $v.id;
      _value = $v.value;
      _referencePending = $v.referencePending;
      _playerId = $v.playerId;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant PhysicalTestResult other) {
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
            expectedBand: expectedBand,
            normId: normId,
            testTypeId: BuiltValueNullFieldError.checkNotNull(
                testTypeId, r'PhysicalTestResult', 'testTypeId'),
            testCode: BuiltValueNullFieldError.checkNotNull(
                testCode, r'PhysicalTestResult', 'testCode'),
            unit: BuiltValueNullFieldError.checkNotNull(
                unit, r'PhysicalTestResult', 'unit'),
            notes: notes,
            measuredOn: BuiltValueNullFieldError.checkNotNull(
                measuredOn, r'PhysicalTestResult', 'measuredOn'),
            ageAtMeasurement: BuiltValueNullFieldError.checkNotNull(
                ageAtMeasurement, r'PhysicalTestResult', 'ageAtMeasurement'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PhysicalTestResult', 'id'),
            value: BuiltValueNullFieldError.checkNotNull(
                value, r'PhysicalTestResult', 'value'),
            referencePending: BuiltValueNullFieldError.checkNotNull(
                referencePending, r'PhysicalTestResult', 'referencePending'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PhysicalTestResult', 'playerId'),
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PhysicalTestResult', 'recordedAt'),
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
