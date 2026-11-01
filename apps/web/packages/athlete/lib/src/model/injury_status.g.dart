// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injury_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InjuryStatus _$OPEN = const InjuryStatus._('OPEN');
const InjuryStatus _$RECOVERED = const InjuryStatus._('RECOVERED');
const InjuryStatus _$unknownDefaultOpenApi =
    const InjuryStatus._('unknownDefaultOpenApi');

InjuryStatus _$valueOf(String name) {
  switch (name) {
    case 'OPEN':
      return _$OPEN;
    case 'RECOVERED':
      return _$RECOVERED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<InjuryStatus> _$values =
    BuiltSet<InjuryStatus>(const <InjuryStatus>[
  _$OPEN,
  _$RECOVERED,
  _$unknownDefaultOpenApi,
]);

class _$InjuryStatusMeta {
  const _$InjuryStatusMeta();
  InjuryStatus get OPEN => _$OPEN;
  InjuryStatus get RECOVERED => _$RECOVERED;
  InjuryStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  InjuryStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<InjuryStatus> get values => _$values;
}

abstract class _$InjuryStatusMixin {
  // ignore: non_constant_identifier_names
  _$InjuryStatusMeta get InjuryStatus => const _$InjuryStatusMeta();
}

Serializer<InjuryStatus> _$injuryStatusSerializer = _$InjuryStatusSerializer();

class _$InjuryStatusSerializer implements PrimitiveSerializer<InjuryStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OPEN': 'OPEN',
    'RECOVERED': 'RECOVERED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OPEN': 'OPEN',
    'RECOVERED': 'RECOVERED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[InjuryStatus];
  @override
  final String wireName = 'InjuryStatus';

  @override
  Object serialize(Serializers serializers, InjuryStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InjuryStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InjuryStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
