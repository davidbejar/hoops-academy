// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EligibilityResult _$ELIGIBLE = const EligibilityResult._('ELIGIBLE');
const EligibilityResult _$PLAY_UP = const EligibilityResult._('PLAY_UP');
const EligibilityResult _$INELIGIBLE = const EligibilityResult._('INELIGIBLE');
const EligibilityResult _$unknownDefaultOpenApi =
    const EligibilityResult._('unknownDefaultOpenApi');

EligibilityResult _$valueOf(String name) {
  switch (name) {
    case 'ELIGIBLE':
      return _$ELIGIBLE;
    case 'PLAY_UP':
      return _$PLAY_UP;
    case 'INELIGIBLE':
      return _$INELIGIBLE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<EligibilityResult> _$values =
    BuiltSet<EligibilityResult>(const <EligibilityResult>[
  _$ELIGIBLE,
  _$PLAY_UP,
  _$INELIGIBLE,
  _$unknownDefaultOpenApi,
]);

class _$EligibilityResultMeta {
  const _$EligibilityResultMeta();
  EligibilityResult get ELIGIBLE => _$ELIGIBLE;
  EligibilityResult get PLAY_UP => _$PLAY_UP;
  EligibilityResult get INELIGIBLE => _$INELIGIBLE;
  EligibilityResult get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  EligibilityResult valueOf(String name) => _$valueOf(name);
  BuiltSet<EligibilityResult> get values => _$values;
}

abstract class _$EligibilityResultMixin {
  // ignore: non_constant_identifier_names
  _$EligibilityResultMeta get EligibilityResult =>
      const _$EligibilityResultMeta();
}

Serializer<EligibilityResult> _$eligibilityResultSerializer =
    _$EligibilityResultSerializer();

class _$EligibilityResultSerializer
    implements PrimitiveSerializer<EligibilityResult> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ELIGIBLE': 'ELIGIBLE',
    'PLAY_UP': 'PLAY_UP',
    'INELIGIBLE': 'INELIGIBLE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ELIGIBLE': 'ELIGIBLE',
    'PLAY_UP': 'PLAY_UP',
    'INELIGIBLE': 'INELIGIBLE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[EligibilityResult];
  @override
  final String wireName = 'EligibilityResult';

  @override
  Object serialize(Serializers serializers, EligibilityResult object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EligibilityResult deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EligibilityResult.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
