// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gender_policy.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GenderPolicy _$MALE = const GenderPolicy._('MALE');
const GenderPolicy _$FEMALE = const GenderPolicy._('FEMALE');
const GenderPolicy _$MIXED = const GenderPolicy._('MIXED');
const GenderPolicy _$unknownDefaultOpenApi =
    const GenderPolicy._('unknownDefaultOpenApi');

GenderPolicy _$valueOf(String name) {
  switch (name) {
    case 'MALE':
      return _$MALE;
    case 'FEMALE':
      return _$FEMALE;
    case 'MIXED':
      return _$MIXED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<GenderPolicy> _$values =
    BuiltSet<GenderPolicy>(const <GenderPolicy>[
  _$MALE,
  _$FEMALE,
  _$MIXED,
  _$unknownDefaultOpenApi,
]);

class _$GenderPolicyMeta {
  const _$GenderPolicyMeta();
  GenderPolicy get MALE => _$MALE;
  GenderPolicy get FEMALE => _$FEMALE;
  GenderPolicy get MIXED => _$MIXED;
  GenderPolicy get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  GenderPolicy valueOf(String name) => _$valueOf(name);
  BuiltSet<GenderPolicy> get values => _$values;
}

abstract class _$GenderPolicyMixin {
  // ignore: non_constant_identifier_names
  _$GenderPolicyMeta get GenderPolicy => const _$GenderPolicyMeta();
}

Serializer<GenderPolicy> _$genderPolicySerializer = _$GenderPolicySerializer();

class _$GenderPolicySerializer implements PrimitiveSerializer<GenderPolicy> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MALE': 'MALE',
    'FEMALE': 'FEMALE',
    'MIXED': 'MIXED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MALE': 'MALE',
    'FEMALE': 'FEMALE',
    'MIXED': 'MIXED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[GenderPolicy];
  @override
  final String wireName = 'GenderPolicy';

  @override
  Object serialize(Serializers serializers, GenderPolicy object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  GenderPolicy deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      GenderPolicy.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
