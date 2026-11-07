//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'staff_role.g.dart';

/// Role of a person within a team's staff (subset of TenantRole).
class StaffRole extends EnumClass {
  @BuiltValueEnumConst(wireName: r'COACH')
  static const StaffRole COACH = _$COACH;
  @BuiltValueEnumConst(wireName: r'ASSISTANT_COACH')
  static const StaffRole ASSISTANT_COACH = _$ASSISTANT_COACH;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const StaffRole unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<StaffRole> get serializer => _$staffRoleSerializer;

  const StaffRole._(String name) : super(name);

  static BuiltSet<StaffRole> get values => _$values;
  static StaffRole valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class StaffRoleMixin = Object with _$StaffRoleMixin;
