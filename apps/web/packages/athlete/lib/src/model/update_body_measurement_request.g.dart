// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_body_measurement_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateBodyMeasurementRequestClearEnum
    _$updateBodyMeasurementRequestClearEnum_heightCm =
    const UpdateBodyMeasurementRequestClearEnum._('heightCm');
const UpdateBodyMeasurementRequestClearEnum
    _$updateBodyMeasurementRequestClearEnum_weightKg =
    const UpdateBodyMeasurementRequestClearEnum._('weightKg');
const UpdateBodyMeasurementRequestClearEnum
    _$updateBodyMeasurementRequestClearEnum_unknownDefaultOpenApi =
    const UpdateBodyMeasurementRequestClearEnum._('unknownDefaultOpenApi');

UpdateBodyMeasurementRequestClearEnum
    _$updateBodyMeasurementRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'heightCm':
      return _$updateBodyMeasurementRequestClearEnum_heightCm;
    case 'weightKg':
      return _$updateBodyMeasurementRequestClearEnum_weightKg;
    case 'unknownDefaultOpenApi':
      return _$updateBodyMeasurementRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateBodyMeasurementRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateBodyMeasurementRequestClearEnum>
    _$updateBodyMeasurementRequestClearEnumValues = BuiltSet<
        UpdateBodyMeasurementRequestClearEnum>(const <UpdateBodyMeasurementRequestClearEnum>[
  _$updateBodyMeasurementRequestClearEnum_heightCm,
  _$updateBodyMeasurementRequestClearEnum_weightKg,
  _$updateBodyMeasurementRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateBodyMeasurementRequestClearEnum>
    _$updateBodyMeasurementRequestClearEnumSerializer =
    _$UpdateBodyMeasurementRequestClearEnumSerializer();

class _$UpdateBodyMeasurementRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateBodyMeasurementRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'heightCm': 'heightCm',
    'weightKg': 'weightKg',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'heightCm': 'heightCm',
    'weightKg': 'weightKg',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdateBodyMeasurementRequestClearEnum
  ];
  @override
  final String wireName = 'UpdateBodyMeasurementRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateBodyMeasurementRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateBodyMeasurementRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateBodyMeasurementRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateBodyMeasurementRequest extends UpdateBodyMeasurementRequest {
  @override
  final Date? measuredOn;
  @override
  final double? heightCm;
  @override
  final double? weightKg;
  @override
  final BuiltSet<UpdateBodyMeasurementRequestClearEnum>? clear;

  factory _$UpdateBodyMeasurementRequest(
          [void Function(UpdateBodyMeasurementRequestBuilder)? updates]) =>
      (UpdateBodyMeasurementRequestBuilder()..update(updates))._build();

  _$UpdateBodyMeasurementRequest._(
      {this.measuredOn, this.heightCm, this.weightKg, this.clear})
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
        weightKg == other.weightKg &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, heightCm.hashCode);
    _$hash = $jc(_$hash, weightKg.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateBodyMeasurementRequest')
          ..add('measuredOn', measuredOn)
          ..add('heightCm', heightCm)
          ..add('weightKg', weightKg)
          ..add('clear', clear))
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

  SetBuilder<UpdateBodyMeasurementRequestClearEnum>? _clear;
  SetBuilder<UpdateBodyMeasurementRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateBodyMeasurementRequestClearEnum>();
  set clear(SetBuilder<UpdateBodyMeasurementRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateBodyMeasurementRequestBuilder() {
    UpdateBodyMeasurementRequest._defaults(this);
  }

  UpdateBodyMeasurementRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _measuredOn = $v.measuredOn;
      _heightCm = $v.heightCm;
      _weightKg = $v.weightKg;
      _clear = $v.clear?.toBuilder();
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
    _$UpdateBodyMeasurementRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateBodyMeasurementRequest._(
            measuredOn: measuredOn,
            heightCm: heightCm,
            weightKg: weightKg,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateBodyMeasurementRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
