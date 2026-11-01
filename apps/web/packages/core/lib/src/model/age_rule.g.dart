// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_rule.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AgeRule _$BIRTH_YEAR = const AgeRule._('BIRTH_YEAR');
const AgeRule _$BIRTHDAY = const AgeRule._('BIRTHDAY');
const AgeRule _$unknownDefaultOpenApi =
    const AgeRule._('unknownDefaultOpenApi');

AgeRule _$valueOf(String name) {
  switch (name) {
    case 'BIRTH_YEAR':
      return _$BIRTH_YEAR;
    case 'BIRTHDAY':
      return _$BIRTHDAY;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AgeRule> _$values = BuiltSet<AgeRule>(const <AgeRule>[
  _$BIRTH_YEAR,
  _$BIRTHDAY,
  _$unknownDefaultOpenApi,
]);

class _$AgeRuleMeta {
  const _$AgeRuleMeta();
  AgeRule get BIRTH_YEAR => _$BIRTH_YEAR;
  AgeRule get BIRTHDAY => _$BIRTHDAY;
  AgeRule get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AgeRule valueOf(String name) => _$valueOf(name);
  BuiltSet<AgeRule> get values => _$values;
}

abstract class _$AgeRuleMixin {
  // ignore: non_constant_identifier_names
  _$AgeRuleMeta get AgeRule => const _$AgeRuleMeta();
}

Serializer<AgeRule> _$ageRuleSerializer = _$AgeRuleSerializer();

class _$AgeRuleSerializer implements PrimitiveSerializer<AgeRule> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'BIRTH_YEAR': 'BIRTH_YEAR',
    'BIRTHDAY': 'BIRTHDAY',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BIRTH_YEAR': 'BIRTH_YEAR',
    'BIRTHDAY': 'BIRTHDAY',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AgeRule];
  @override
  final String wireName = 'AgeRule';

  @override
  Object serialize(Serializers serializers, AgeRule object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AgeRule deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AgeRule.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
