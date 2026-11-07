// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_request_role.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AcademyRequestRole _$ADMIN = const AcademyRequestRole._('ADMIN');
const AcademyRequestRole _$COACH = const AcademyRequestRole._('COACH');
const AcademyRequestRole _$PARENT = const AcademyRequestRole._('PARENT');
const AcademyRequestRole _$unknownDefaultOpenApi =
    const AcademyRequestRole._('unknownDefaultOpenApi');

AcademyRequestRole _$valueOf(String name) {
  switch (name) {
    case 'ADMIN':
      return _$ADMIN;
    case 'COACH':
      return _$COACH;
    case 'PARENT':
      return _$PARENT;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AcademyRequestRole> _$values =
    BuiltSet<AcademyRequestRole>(const <AcademyRequestRole>[
  _$ADMIN,
  _$COACH,
  _$PARENT,
  _$unknownDefaultOpenApi,
]);

class _$AcademyRequestRoleMeta {
  const _$AcademyRequestRoleMeta();
  AcademyRequestRole get ADMIN => _$ADMIN;
  AcademyRequestRole get COACH => _$COACH;
  AcademyRequestRole get PARENT => _$PARENT;
  AcademyRequestRole get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AcademyRequestRole valueOf(String name) => _$valueOf(name);
  BuiltSet<AcademyRequestRole> get values => _$values;
}

abstract class _$AcademyRequestRoleMixin {
  // ignore: non_constant_identifier_names
  _$AcademyRequestRoleMeta get AcademyRequestRole =>
      const _$AcademyRequestRoleMeta();
}

Serializer<AcademyRequestRole> _$academyRequestRoleSerializer =
    _$AcademyRequestRoleSerializer();

class _$AcademyRequestRoleSerializer
    implements PrimitiveSerializer<AcademyRequestRole> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ADMIN': 'ADMIN',
    'COACH': 'COACH',
    'PARENT': 'PARENT',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ADMIN': 'ADMIN',
    'COACH': 'COACH',
    'PARENT': 'PARENT',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AcademyRequestRole];
  @override
  final String wireName = 'AcademyRequestRole';

  @override
  Object serialize(Serializers serializers, AcademyRequestRole object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AcademyRequestRole deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AcademyRequestRole.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
