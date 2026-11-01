// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'norm_band.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NormBand _$POOR = const NormBand._('POOR');
const NormBand _$BELOW_AVERAGE = const NormBand._('BELOW_AVERAGE');
const NormBand _$AVERAGE = const NormBand._('AVERAGE');
const NormBand _$ABOVE_AVERAGE = const NormBand._('ABOVE_AVERAGE');
const NormBand _$EXCELLENT = const NormBand._('EXCELLENT');
const NormBand _$unknownDefaultOpenApi =
    const NormBand._('unknownDefaultOpenApi');

NormBand _$valueOf(String name) {
  switch (name) {
    case 'POOR':
      return _$POOR;
    case 'BELOW_AVERAGE':
      return _$BELOW_AVERAGE;
    case 'AVERAGE':
      return _$AVERAGE;
    case 'ABOVE_AVERAGE':
      return _$ABOVE_AVERAGE;
    case 'EXCELLENT':
      return _$EXCELLENT;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<NormBand> _$values = BuiltSet<NormBand>(const <NormBand>[
  _$POOR,
  _$BELOW_AVERAGE,
  _$AVERAGE,
  _$ABOVE_AVERAGE,
  _$EXCELLENT,
  _$unknownDefaultOpenApi,
]);

class _$NormBandMeta {
  const _$NormBandMeta();
  NormBand get POOR => _$POOR;
  NormBand get BELOW_AVERAGE => _$BELOW_AVERAGE;
  NormBand get AVERAGE => _$AVERAGE;
  NormBand get ABOVE_AVERAGE => _$ABOVE_AVERAGE;
  NormBand get EXCELLENT => _$EXCELLENT;
  NormBand get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  NormBand valueOf(String name) => _$valueOf(name);
  BuiltSet<NormBand> get values => _$values;
}

abstract class _$NormBandMixin {
  // ignore: non_constant_identifier_names
  _$NormBandMeta get NormBand => const _$NormBandMeta();
}

Serializer<NormBand> _$normBandSerializer = _$NormBandSerializer();

class _$NormBandSerializer implements PrimitiveSerializer<NormBand> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'POOR': 'POOR',
    'BELOW_AVERAGE': 'BELOW_AVERAGE',
    'AVERAGE': 'AVERAGE',
    'ABOVE_AVERAGE': 'ABOVE_AVERAGE',
    'EXCELLENT': 'EXCELLENT',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'POOR': 'POOR',
    'BELOW_AVERAGE': 'BELOW_AVERAGE',
    'AVERAGE': 'AVERAGE',
    'ABOVE_AVERAGE': 'ABOVE_AVERAGE',
    'EXCELLENT': 'EXCELLENT',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[NormBand];
  @override
  final String wireName = 'NormBand';

  @override
  Object serialize(Serializers serializers, NormBand object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  NormBand deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      NormBand.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
