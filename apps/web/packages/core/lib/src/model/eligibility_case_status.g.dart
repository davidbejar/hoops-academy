// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_case_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EligibilityCaseStatus _$OPEN = const EligibilityCaseStatus._('OPEN');
const EligibilityCaseStatus _$RESOLVED =
    const EligibilityCaseStatus._('RESOLVED');
const EligibilityCaseStatus _$unknownDefaultOpenApi =
    const EligibilityCaseStatus._('unknownDefaultOpenApi');

EligibilityCaseStatus _$valueOf(String name) {
  switch (name) {
    case 'OPEN':
      return _$OPEN;
    case 'RESOLVED':
      return _$RESOLVED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<EligibilityCaseStatus> _$values =
    BuiltSet<EligibilityCaseStatus>(const <EligibilityCaseStatus>[
  _$OPEN,
  _$RESOLVED,
  _$unknownDefaultOpenApi,
]);

class _$EligibilityCaseStatusMeta {
  const _$EligibilityCaseStatusMeta();
  EligibilityCaseStatus get OPEN => _$OPEN;
  EligibilityCaseStatus get RESOLVED => _$RESOLVED;
  EligibilityCaseStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  EligibilityCaseStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<EligibilityCaseStatus> get values => _$values;
}

abstract class _$EligibilityCaseStatusMixin {
  // ignore: non_constant_identifier_names
  _$EligibilityCaseStatusMeta get EligibilityCaseStatus =>
      const _$EligibilityCaseStatusMeta();
}

Serializer<EligibilityCaseStatus> _$eligibilityCaseStatusSerializer =
    _$EligibilityCaseStatusSerializer();

class _$EligibilityCaseStatusSerializer
    implements PrimitiveSerializer<EligibilityCaseStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OPEN': 'OPEN',
    'RESOLVED': 'RESOLVED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OPEN': 'OPEN',
    'RESOLVED': 'RESOLVED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[EligibilityCaseStatus];
  @override
  final String wireName = 'EligibilityCaseStatus';

  @override
  Object serialize(Serializers serializers, EligibilityCaseStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EligibilityCaseStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EligibilityCaseStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
