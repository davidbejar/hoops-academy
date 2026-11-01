// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gender.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Gender _$MALE = const Gender._('MALE');
const Gender _$FEMALE = const Gender._('FEMALE');
const Gender _$unknownDefaultOpenApi = const Gender._('unknownDefaultOpenApi');

Gender _$valueOf(String name) {
  switch (name) {
    case 'MALE':
      return _$MALE;
    case 'FEMALE':
      return _$FEMALE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<Gender> _$values = BuiltSet<Gender>(const <Gender>[
  _$MALE,
  _$FEMALE,
  _$unknownDefaultOpenApi,
]);

class _$GenderMeta {
  const _$GenderMeta();
  Gender get MALE => _$MALE;
  Gender get FEMALE => _$FEMALE;
  Gender get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  Gender valueOf(String name) => _$valueOf(name);
  BuiltSet<Gender> get values => _$values;
}

abstract class _$GenderMixin {
  // ignore: non_constant_identifier_names
  _$GenderMeta get Gender => const _$GenderMeta();
}

Serializer<Gender> _$genderSerializer = _$GenderSerializer();

class _$GenderSerializer implements PrimitiveSerializer<Gender> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MALE': 'MALE',
    'FEMALE': 'FEMALE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MALE': 'MALE',
    'FEMALE': 'FEMALE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[Gender];
  @override
  final String wireName = 'Gender';

  @override
  Object serialize(Serializers serializers, Gender object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  Gender deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Gender.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
