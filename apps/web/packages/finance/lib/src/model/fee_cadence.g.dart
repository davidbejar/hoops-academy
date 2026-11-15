// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_cadence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FeeCadence _$MONTHLY = const FeeCadence._('MONTHLY');
const FeeCadence _$QUARTERLY = const FeeCadence._('QUARTERLY');
const FeeCadence _$SEASON = const FeeCadence._('SEASON');
const FeeCadence _$unknownDefaultOpenApi =
    const FeeCadence._('unknownDefaultOpenApi');

FeeCadence _$valueOf(String name) {
  switch (name) {
    case 'MONTHLY':
      return _$MONTHLY;
    case 'QUARTERLY':
      return _$QUARTERLY;
    case 'SEASON':
      return _$SEASON;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<FeeCadence> _$values = BuiltSet<FeeCadence>(const <FeeCadence>[
  _$MONTHLY,
  _$QUARTERLY,
  _$SEASON,
  _$unknownDefaultOpenApi,
]);

class _$FeeCadenceMeta {
  const _$FeeCadenceMeta();
  FeeCadence get MONTHLY => _$MONTHLY;
  FeeCadence get QUARTERLY => _$QUARTERLY;
  FeeCadence get SEASON => _$SEASON;
  FeeCadence get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  FeeCadence valueOf(String name) => _$valueOf(name);
  BuiltSet<FeeCadence> get values => _$values;
}

abstract class _$FeeCadenceMixin {
  // ignore: non_constant_identifier_names
  _$FeeCadenceMeta get FeeCadence => const _$FeeCadenceMeta();
}

Serializer<FeeCadence> _$feeCadenceSerializer = _$FeeCadenceSerializer();

class _$FeeCadenceSerializer implements PrimitiveSerializer<FeeCadence> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MONTHLY': 'MONTHLY',
    'QUARTERLY': 'QUARTERLY',
    'SEASON': 'SEASON',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MONTHLY': 'MONTHLY',
    'QUARTERLY': 'QUARTERLY',
    'SEASON': 'SEASON',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[FeeCadence];
  @override
  final String wireName = 'FeeCadence';

  @override
  Object serialize(Serializers serializers, FeeCadence object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FeeCadence deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FeeCadence.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
