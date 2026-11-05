// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_target_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AuditTargetType _$person = const AuditTargetType._('person');
const AuditTargetType _$player = const AuditTargetType._('player');
const AuditTargetType _$tenant = const AuditTargetType._('tenant');
const AuditTargetType _$approvalRequest =
    const AuditTargetType._('approvalRequest');
const AuditTargetType _$guardianLink = const AuditTargetType._('guardianLink');
const AuditTargetType _$unknownDefaultOpenApi =
    const AuditTargetType._('unknownDefaultOpenApi');

AuditTargetType _$valueOf(String name) {
  switch (name) {
    case 'person':
      return _$person;
    case 'player':
      return _$player;
    case 'tenant':
      return _$tenant;
    case 'approvalRequest':
      return _$approvalRequest;
    case 'guardianLink':
      return _$guardianLink;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AuditTargetType> _$values =
    BuiltSet<AuditTargetType>(const <AuditTargetType>[
  _$person,
  _$player,
  _$tenant,
  _$approvalRequest,
  _$guardianLink,
  _$unknownDefaultOpenApi,
]);

class _$AuditTargetTypeMeta {
  const _$AuditTargetTypeMeta();
  AuditTargetType get person => _$person;
  AuditTargetType get player => _$player;
  AuditTargetType get tenant => _$tenant;
  AuditTargetType get approvalRequest => _$approvalRequest;
  AuditTargetType get guardianLink => _$guardianLink;
  AuditTargetType get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AuditTargetType valueOf(String name) => _$valueOf(name);
  BuiltSet<AuditTargetType> get values => _$values;
}

abstract class _$AuditTargetTypeMixin {
  // ignore: non_constant_identifier_names
  _$AuditTargetTypeMeta get AuditTargetType => const _$AuditTargetTypeMeta();
}

Serializer<AuditTargetType> _$auditTargetTypeSerializer =
    _$AuditTargetTypeSerializer();

class _$AuditTargetTypeSerializer
    implements PrimitiveSerializer<AuditTargetType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'person': 'person',
    'player': 'player',
    'tenant': 'tenant',
    'approvalRequest': 'approval_request',
    'guardianLink': 'guardian_link',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'person': 'person',
    'player': 'player',
    'tenant': 'tenant',
    'approval_request': 'approvalRequest',
    'guardian_link': 'guardianLink',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AuditTargetType];
  @override
  final String wireName = 'AuditTargetType';

  @override
  Object serialize(Serializers serializers, AuditTargetType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AuditTargetType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AuditTargetType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
