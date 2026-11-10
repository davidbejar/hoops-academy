//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_role.g.dart';

class TenantRole extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const TenantRole ADMIN = _$ADMIN;
  @BuiltValueEnumConst(wireName: r'COACH')
  static const TenantRole COACH = _$COACH;
  @BuiltValueEnumConst(wireName: r'ASSISTANT_COACH')
  static const TenantRole ASSISTANT_COACH = _$ASSISTANT_COACH;
  @BuiltValueEnumConst(wireName: r'PARENT')
  static const TenantRole PARENT = _$PARENT;
  @BuiltValueEnumConst(wireName: r'PLAYER')
  static const TenantRole PLAYER = _$PLAYER;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TenantRole unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<TenantRole> get serializer => _$tenantRoleSerializer;

  const TenantRole._(String name): super(name);

  static BuiltSet<TenantRole> get values => _$values;
  static TenantRole valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TenantRoleMixin = Object with _$TenantRoleMixin;

