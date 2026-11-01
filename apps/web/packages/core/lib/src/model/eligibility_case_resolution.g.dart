// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_case_resolution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EligibilityCaseResolution _$REASSIGNED =
    const EligibilityCaseResolution._('REASSIGNED');
const EligibilityCaseResolution _$REMOVED_FROM_TEAM =
    const EligibilityCaseResolution._('REMOVED_FROM_TEAM');
const EligibilityCaseResolution _$DISMISSED =
    const EligibilityCaseResolution._('DISMISSED');
const EligibilityCaseResolution _$unknownDefaultOpenApi =
    const EligibilityCaseResolution._('unknownDefaultOpenApi');

EligibilityCaseResolution _$valueOf(String name) {
  switch (name) {
    case 'REASSIGNED':
      return _$REASSIGNED;
    case 'REMOVED_FROM_TEAM':
      return _$REMOVED_FROM_TEAM;
    case 'DISMISSED':
      return _$DISMISSED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<EligibilityCaseResolution> _$values =
    BuiltSet<EligibilityCaseResolution>(const <EligibilityCaseResolution>[
  _$REASSIGNED,
  _$REMOVED_FROM_TEAM,
  _$DISMISSED,
  _$unknownDefaultOpenApi,
]);

class _$EligibilityCaseResolutionMeta {
  const _$EligibilityCaseResolutionMeta();
  EligibilityCaseResolution get REASSIGNED => _$REASSIGNED;
  EligibilityCaseResolution get REMOVED_FROM_TEAM => _$REMOVED_FROM_TEAM;
  EligibilityCaseResolution get DISMISSED => _$DISMISSED;
  EligibilityCaseResolution get unknownDefaultOpenApi =>
      _$unknownDefaultOpenApi;
  EligibilityCaseResolution valueOf(String name) => _$valueOf(name);
  BuiltSet<EligibilityCaseResolution> get values => _$values;
}

abstract class _$EligibilityCaseResolutionMixin {
  // ignore: non_constant_identifier_names
  _$EligibilityCaseResolutionMeta get EligibilityCaseResolution =>
      const _$EligibilityCaseResolutionMeta();
}

Serializer<EligibilityCaseResolution> _$eligibilityCaseResolutionSerializer =
    _$EligibilityCaseResolutionSerializer();

class _$EligibilityCaseResolutionSerializer
    implements PrimitiveSerializer<EligibilityCaseResolution> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'REASSIGNED': 'REASSIGNED',
    'REMOVED_FROM_TEAM': 'REMOVED_FROM_TEAM',
    'DISMISSED': 'DISMISSED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'REASSIGNED': 'REASSIGNED',
    'REMOVED_FROM_TEAM': 'REMOVED_FROM_TEAM',
    'DISMISSED': 'DISMISSED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[EligibilityCaseResolution];
  @override
  final String wireName = 'EligibilityCaseResolution';

  @override
  Object serialize(Serializers serializers, EligibilityCaseResolution object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EligibilityCaseResolution deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EligibilityCaseResolution.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
