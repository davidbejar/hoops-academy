// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_reason.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EligibilityReason _$CATEGORY_TOO_LOW =
    const EligibilityReason._('CATEGORY_TOO_LOW');
const EligibilityReason _$PLAY_UP_LIMIT_EXCEEDED =
    const EligibilityReason._('PLAY_UP_LIMIT_EXCEEDED');
const EligibilityReason _$GENDER_POLICY =
    const EligibilityReason._('GENDER_POLICY');
const EligibilityReason _$MISSING_BIRTH_DATE =
    const EligibilityReason._('MISSING_BIRTH_DATE');
const EligibilityReason _$MISSING_GENDER =
    const EligibilityReason._('MISSING_GENDER');
const EligibilityReason _$PLAYER_NOT_ACTIVE =
    const EligibilityReason._('PLAYER_NOT_ACTIVE');
const EligibilityReason _$unknownDefaultOpenApi =
    const EligibilityReason._('unknownDefaultOpenApi');

EligibilityReason _$valueOf(String name) {
  switch (name) {
    case 'CATEGORY_TOO_LOW':
      return _$CATEGORY_TOO_LOW;
    case 'PLAY_UP_LIMIT_EXCEEDED':
      return _$PLAY_UP_LIMIT_EXCEEDED;
    case 'GENDER_POLICY':
      return _$GENDER_POLICY;
    case 'MISSING_BIRTH_DATE':
      return _$MISSING_BIRTH_DATE;
    case 'MISSING_GENDER':
      return _$MISSING_GENDER;
    case 'PLAYER_NOT_ACTIVE':
      return _$PLAYER_NOT_ACTIVE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<EligibilityReason> _$values =
    BuiltSet<EligibilityReason>(const <EligibilityReason>[
  _$CATEGORY_TOO_LOW,
  _$PLAY_UP_LIMIT_EXCEEDED,
  _$GENDER_POLICY,
  _$MISSING_BIRTH_DATE,
  _$MISSING_GENDER,
  _$PLAYER_NOT_ACTIVE,
  _$unknownDefaultOpenApi,
]);

class _$EligibilityReasonMeta {
  const _$EligibilityReasonMeta();
  EligibilityReason get CATEGORY_TOO_LOW => _$CATEGORY_TOO_LOW;
  EligibilityReason get PLAY_UP_LIMIT_EXCEEDED => _$PLAY_UP_LIMIT_EXCEEDED;
  EligibilityReason get GENDER_POLICY => _$GENDER_POLICY;
  EligibilityReason get MISSING_BIRTH_DATE => _$MISSING_BIRTH_DATE;
  EligibilityReason get MISSING_GENDER => _$MISSING_GENDER;
  EligibilityReason get PLAYER_NOT_ACTIVE => _$PLAYER_NOT_ACTIVE;
  EligibilityReason get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  EligibilityReason valueOf(String name) => _$valueOf(name);
  BuiltSet<EligibilityReason> get values => _$values;
}

abstract class _$EligibilityReasonMixin {
  // ignore: non_constant_identifier_names
  _$EligibilityReasonMeta get EligibilityReason =>
      const _$EligibilityReasonMeta();
}

Serializer<EligibilityReason> _$eligibilityReasonSerializer =
    _$EligibilityReasonSerializer();

class _$EligibilityReasonSerializer
    implements PrimitiveSerializer<EligibilityReason> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CATEGORY_TOO_LOW': 'CATEGORY_TOO_LOW',
    'PLAY_UP_LIMIT_EXCEEDED': 'PLAY_UP_LIMIT_EXCEEDED',
    'GENDER_POLICY': 'GENDER_POLICY',
    'MISSING_BIRTH_DATE': 'MISSING_BIRTH_DATE',
    'MISSING_GENDER': 'MISSING_GENDER',
    'PLAYER_NOT_ACTIVE': 'PLAYER_NOT_ACTIVE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CATEGORY_TOO_LOW': 'CATEGORY_TOO_LOW',
    'PLAY_UP_LIMIT_EXCEEDED': 'PLAY_UP_LIMIT_EXCEEDED',
    'GENDER_POLICY': 'GENDER_POLICY',
    'MISSING_BIRTH_DATE': 'MISSING_BIRTH_DATE',
    'MISSING_GENDER': 'MISSING_GENDER',
    'PLAYER_NOT_ACTIVE': 'PLAYER_NOT_ACTIVE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[EligibilityReason];
  @override
  final String wireName = 'EligibilityReason';

  @override
  Object serialize(Serializers serializers, EligibilityReason object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EligibilityReason deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EligibilityReason.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
