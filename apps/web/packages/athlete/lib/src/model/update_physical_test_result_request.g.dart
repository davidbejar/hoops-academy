// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_physical_test_result_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePhysicalTestResultRequest
    extends UpdatePhysicalTestResultRequest {
  @override
  final Date? measuredOn;
  @override
  final double? value;
  @override
  final String? notes;

  factory _$UpdatePhysicalTestResultRequest(
          [void Function(UpdatePhysicalTestResultRequestBuilder)? updates]) =>
      (UpdatePhysicalTestResultRequestBuilder()..update(updates))._build();

  _$UpdatePhysicalTestResultRequest._({this.measuredOn, this.value, this.notes})
      : super._();
  @override
  UpdatePhysicalTestResultRequest rebuild(
          void Function(UpdatePhysicalTestResultRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePhysicalTestResultRequestBuilder toBuilder() =>
      UpdatePhysicalTestResultRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePhysicalTestResultRequest &&
        measuredOn == other.measuredOn &&
        value == other.value &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePhysicalTestResultRequest')
          ..add('measuredOn', measuredOn)
          ..add('value', value)
          ..add('notes', notes))
        .toString();
  }
}

class UpdatePhysicalTestResultRequestBuilder
    implements
        Builder<UpdatePhysicalTestResultRequest,
            UpdatePhysicalTestResultRequestBuilder> {
  _$UpdatePhysicalTestResultRequest? _$v;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _value;
  double? get value => _$this._value;
  set value(double? value) => _$this._value = value;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  UpdatePhysicalTestResultRequestBuilder() {
    UpdatePhysicalTestResultRequest._defaults(this);
  }

  UpdatePhysicalTestResultRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _measuredOn = $v.measuredOn;
      _value = $v.value;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePhysicalTestResultRequest other) {
    _$v = other as _$UpdatePhysicalTestResultRequest;
  }

  @override
  void update(void Function(UpdatePhysicalTestResultRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePhysicalTestResultRequest build() => _build();

  _$UpdatePhysicalTestResultRequest _build() {
    final _$result = _$v ??
        _$UpdatePhysicalTestResultRequest._(
          measuredOn: measuredOn,
          value: value,
          notes: notes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
