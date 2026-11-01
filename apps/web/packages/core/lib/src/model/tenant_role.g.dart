// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_role.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TenantRole _$ADMIN = const TenantRole._('ADMIN');
const TenantRole _$COACH = const TenantRole._('COACH');
const TenantRole _$ASSISTANT_COACH = const TenantRole._('ASSISTANT_COACH');
const TenantRole _$PARENT = const TenantRole._('PARENT');
const TenantRole _$PLAYER = const TenantRole._('PLAYER');
const TenantRole _$unknownDefaultOpenApi =
    const TenantRole._('unknownDefaultOpenApi');

TenantRole _$valueOf(String name) {
  switch (name) {
    case 'ADMIN':
      return _$ADMIN;
    case 'COACH':
      return _$COACH;
    case 'ASSISTANT_COACH':
      return _$ASSISTANT_COACH;
    case 'PARENT':
      return _$PARENT;
    case 'PLAYER':
      return _$PLAYER;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<TenantRole> _$values = BuiltSet<TenantRole>(const <TenantRole>[
  _$ADMIN,
  _$COACH,
  _$ASSISTANT_COACH,
  _$PARENT,
  _$PLAYER,
  _$unknownDefaultOpenApi,
]);

class _$TenantRoleMeta {
  const _$TenantRoleMeta();
  TenantRole get ADMIN => _$ADMIN;
  TenantRole get COACH => _$COACH;
  TenantRole get ASSISTANT_COACH => _$ASSISTANT_COACH;
  TenantRole get PARENT => _$PARENT;
  TenantRole get PLAYER => _$PLAYER;
  TenantRole get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  TenantRole valueOf(String name) => _$valueOf(name);
  BuiltSet<TenantRole> get values => _$values;
}

abstract class _$TenantRoleMixin {
  // ignore: non_constant_identifier_names
  _$TenantRoleMeta get TenantRole => const _$TenantRoleMeta();
}

Serializer<TenantRole> _$tenantRoleSerializer = _$TenantRoleSerializer();

class _$TenantRoleSerializer implements PrimitiveSerializer<TenantRole> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ADMIN': 'ADMIN',
    'COACH': 'COACH',
    'ASSISTANT_COACH': 'ASSISTANT_COACH',
    'PARENT': 'PARENT',
    'PLAYER': 'PLAYER',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ADMIN': 'ADMIN',
    'COACH': 'COACH',
    'ASSISTANT_COACH': 'ASSISTANT_COACH',
    'PARENT': 'PARENT',
    'PLAYER': 'PLAYER',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TenantRole];
  @override
  final String wireName = 'TenantRole';

  @override
  Object serialize(Serializers serializers, TenantRole object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TenantRole deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TenantRole.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
