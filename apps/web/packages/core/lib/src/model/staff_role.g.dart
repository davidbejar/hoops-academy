// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_role.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const StaffRole _$COACH = const StaffRole._('COACH');
const StaffRole _$ASSISTANT_COACH = const StaffRole._('ASSISTANT_COACH');
const StaffRole _$unknownDefaultOpenApi =
    const StaffRole._('unknownDefaultOpenApi');

StaffRole _$valueOf(String name) {
  switch (name) {
    case 'COACH':
      return _$COACH;
    case 'ASSISTANT_COACH':
      return _$ASSISTANT_COACH;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<StaffRole> _$values = BuiltSet<StaffRole>(const <StaffRole>[
  _$COACH,
  _$ASSISTANT_COACH,
  _$unknownDefaultOpenApi,
]);

class _$StaffRoleMeta {
  const _$StaffRoleMeta();
  StaffRole get COACH => _$COACH;
  StaffRole get ASSISTANT_COACH => _$ASSISTANT_COACH;
  StaffRole get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  StaffRole valueOf(String name) => _$valueOf(name);
  BuiltSet<StaffRole> get values => _$values;
}

abstract class _$StaffRoleMixin {
  // ignore: non_constant_identifier_names
  _$StaffRoleMeta get StaffRole => const _$StaffRoleMeta();
}

Serializer<StaffRole> _$staffRoleSerializer = _$StaffRoleSerializer();

class _$StaffRoleSerializer implements PrimitiveSerializer<StaffRole> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'COACH': 'COACH',
    'ASSISTANT_COACH': 'ASSISTANT_COACH',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'COACH': 'COACH',
    'ASSISTANT_COACH': 'ASSISTANT_COACH',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[StaffRole];
  @override
  final String wireName = 'StaffRole';

  @override
  Object serialize(Serializers serializers, StaffRole object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  StaffRole deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      StaffRole.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
