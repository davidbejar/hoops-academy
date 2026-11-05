// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_actor_kind.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AuditActorKind _$PERSON = const AuditActorKind._('PERSON');
const AuditActorKind _$PLATFORM = const AuditActorKind._('PLATFORM');
const AuditActorKind _$SYSTEM = const AuditActorKind._('SYSTEM');
const AuditActorKind _$unknownDefaultOpenApi =
    const AuditActorKind._('unknownDefaultOpenApi');

AuditActorKind _$valueOf(String name) {
  switch (name) {
    case 'PERSON':
      return _$PERSON;
    case 'PLATFORM':
      return _$PLATFORM;
    case 'SYSTEM':
      return _$SYSTEM;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AuditActorKind> _$values =
    BuiltSet<AuditActorKind>(const <AuditActorKind>[
  _$PERSON,
  _$PLATFORM,
  _$SYSTEM,
  _$unknownDefaultOpenApi,
]);

class _$AuditActorKindMeta {
  const _$AuditActorKindMeta();
  AuditActorKind get PERSON => _$PERSON;
  AuditActorKind get PLATFORM => _$PLATFORM;
  AuditActorKind get SYSTEM => _$SYSTEM;
  AuditActorKind get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AuditActorKind valueOf(String name) => _$valueOf(name);
  BuiltSet<AuditActorKind> get values => _$values;
}

abstract class _$AuditActorKindMixin {
  // ignore: non_constant_identifier_names
  _$AuditActorKindMeta get AuditActorKind => const _$AuditActorKindMeta();
}

Serializer<AuditActorKind> _$auditActorKindSerializer =
    _$AuditActorKindSerializer();

class _$AuditActorKindSerializer
    implements PrimitiveSerializer<AuditActorKind> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PERSON': 'PERSON',
    'PLATFORM': 'PLATFORM',
    'SYSTEM': 'SYSTEM',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PERSON': 'PERSON',
    'PLATFORM': 'PLATFORM',
    'SYSTEM': 'SYSTEM',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AuditActorKind];
  @override
  final String wireName = 'AuditActorKind';

  @override
  Object serialize(Serializers serializers, AuditActorKind object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AuditActorKind deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AuditActorKind.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
