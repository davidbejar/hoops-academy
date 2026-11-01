// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_result_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestResultInput extends PhysicalTestResultInput {
  @override
  final String playerId;
  @override
  final String testTypeId;
  @override
  final Date measuredOn;
  @override
  final double value;
  @override
  final String? notes;

  factory _$PhysicalTestResultInput(
          [void Function(PhysicalTestResultInputBuilder)? updates]) =>
      (PhysicalTestResultInputBuilder()..update(updates))._build();

  _$PhysicalTestResultInput._(
      {required this.playerId,
      required this.testTypeId,
      required this.measuredOn,
      required this.value,
      this.notes})
      : super._();
  @override
  PhysicalTestResultInput rebuild(
          void Function(PhysicalTestResultInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhysicalTestResultInputBuilder toBuilder() =>
      PhysicalTestResultInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhysicalTestResultInput &&
        playerId == other.playerId &&
        testTypeId == other.testTypeId &&
        measuredOn == other.measuredOn &&
        value == other.value &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, testTypeId.hashCode);
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhysicalTestResultInput')
          ..add('playerId', playerId)
          ..add('testTypeId', testTypeId)
          ..add('measuredOn', measuredOn)
          ..add('value', value)
          ..add('notes', notes))
        .toString();
  }
}

class PhysicalTestResultInputBuilder
    implements
        Builder<PhysicalTestResultInput, PhysicalTestResultInputBuilder> {
  _$PhysicalTestResultInput? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _testTypeId;
  String? get testTypeId => _$this._testTypeId;
  set testTypeId(String? testTypeId) => _$this._testTypeId = testTypeId;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _value;
  double? get value => _$this._value;
  set value(double? value) => _$this._value = value;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  PhysicalTestResultInputBuilder() {
    PhysicalTestResultInput._defaults(this);
  }

  PhysicalTestResultInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _testTypeId = $v.testTypeId;
      _measuredOn = $v.measuredOn;
      _value = $v.value;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhysicalTestResultInput other) {
    _$v = other as _$PhysicalTestResultInput;
  }

  @override
  void update(void Function(PhysicalTestResultInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhysicalTestResultInput build() => _build();

  _$PhysicalTestResultInput _build() {
    final _$result = _$v ??
        _$PhysicalTestResultInput._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'PhysicalTestResultInput', 'playerId'),
          testTypeId: BuiltValueNullFieldError.checkNotNull(
              testTypeId, r'PhysicalTestResultInput', 'testTypeId'),
          measuredOn: BuiltValueNullFieldError.checkNotNull(
              measuredOn, r'PhysicalTestResultInput', 'measuredOn'),
          value: BuiltValueNullFieldError.checkNotNull(
              value, r'PhysicalTestResultInput', 'value'),
          notes: notes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
