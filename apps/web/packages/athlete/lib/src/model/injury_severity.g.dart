// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injury_severity.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InjurySeverity _$MINOR = const InjurySeverity._('MINOR');
const InjurySeverity _$MODERATE = const InjurySeverity._('MODERATE');
const InjurySeverity _$SEVERE = const InjurySeverity._('SEVERE');
const InjurySeverity _$unknownDefaultOpenApi =
    const InjurySeverity._('unknownDefaultOpenApi');

InjurySeverity _$valueOf(String name) {
  switch (name) {
    case 'MINOR':
      return _$MINOR;
    case 'MODERATE':
      return _$MODERATE;
    case 'SEVERE':
      return _$SEVERE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<InjurySeverity> _$values =
    BuiltSet<InjurySeverity>(const <InjurySeverity>[
  _$MINOR,
  _$MODERATE,
  _$SEVERE,
  _$unknownDefaultOpenApi,
]);

class _$InjurySeverityMeta {
  const _$InjurySeverityMeta();
  InjurySeverity get MINOR => _$MINOR;
  InjurySeverity get MODERATE => _$MODERATE;
  InjurySeverity get SEVERE => _$SEVERE;
  InjurySeverity get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  InjurySeverity valueOf(String name) => _$valueOf(name);
  BuiltSet<InjurySeverity> get values => _$values;
}

abstract class _$InjurySeverityMixin {
  // ignore: non_constant_identifier_names
  _$InjurySeverityMeta get InjurySeverity => const _$InjurySeverityMeta();
}

Serializer<InjurySeverity> _$injurySeveritySerializer =
    _$InjurySeveritySerializer();

class _$InjurySeveritySerializer
    implements PrimitiveSerializer<InjurySeverity> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MINOR': 'MINOR',
    'MODERATE': 'MODERATE',
    'SEVERE': 'SEVERE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MINOR': 'MINOR',
    'MODERATE': 'MODERATE',
    'SEVERE': 'SEVERE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[InjurySeverity];
  @override
  final String wireName = 'InjurySeverity';

  @override
  Object serialize(Serializers serializers, InjurySeverity object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InjurySeverity deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InjurySeverity.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
