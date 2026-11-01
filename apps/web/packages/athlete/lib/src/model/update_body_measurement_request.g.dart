// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_body_measurement_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateBodyMeasurementRequest extends UpdateBodyMeasurementRequest {
  @override
  final Date? measuredOn;
  @override
  final double? heightCm;
  @override
  final double? weightKg;

  factory _$UpdateBodyMeasurementRequest(
          [void Function(UpdateBodyMeasurementRequestBuilder)? updates]) =>
      (UpdateBodyMeasurementRequestBuilder()..update(updates))._build();

  _$UpdateBodyMeasurementRequest._(
      {this.measuredOn, this.heightCm, this.weightKg})
      : super._();
  @override
  UpdateBodyMeasurementRequest rebuild(
          void Function(UpdateBodyMeasurementRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateBodyMeasurementRequestBuilder toBuilder() =>
      UpdateBodyMeasurementRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateBodyMeasurementRequest &&
        measuredOn == other.measuredOn &&
        heightCm == other.heightCm &&
        weightKg == other.weightKg;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, heightCm.hashCode);
    _$hash = $jc(_$hash, weightKg.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateBodyMeasurementRequest')
          ..add('measuredOn', measuredOn)
          ..add('heightCm', heightCm)
          ..add('weightKg', weightKg))
        .toString();
  }
}

class UpdateBodyMeasurementRequestBuilder
    implements
        Builder<UpdateBodyMeasurementRequest,
            UpdateBodyMeasurementRequestBuilder> {
  _$UpdateBodyMeasurementRequest? _$v;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _heightCm;
  double? get heightCm => _$this._heightCm;
  set heightCm(double? heightCm) => _$this._heightCm = heightCm;

  double? _weightKg;
  double? get weightKg => _$this._weightKg;
  set weightKg(double? weightKg) => _$this._weightKg = weightKg;

  UpdateBodyMeasurementRequestBuilder() {
    UpdateBodyMeasurementRequest._defaults(this);
  }

  UpdateBodyMeasurementRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _measuredOn = $v.measuredOn;
      _heightCm = $v.heightCm;
      _weightKg = $v.weightKg;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateBodyMeasurementRequest other) {
    _$v = other as _$UpdateBodyMeasurementRequest;
  }

  @override
  void update(void Function(UpdateBodyMeasurementRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateBodyMeasurementRequest build() => _build();

  _$UpdateBodyMeasurementRequest _build() {
    final _$result = _$v ??
        _$UpdateBodyMeasurementRequest._(
          measuredOn: measuredOn,
          heightCm: heightCm,
          weightKg: weightKg,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
