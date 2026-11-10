//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'academy_request_role.g.dart';

/// What the requester is at the academy; players never request (decision 58). Accepted → first ADMIN.
class AcademyRequestRole extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const AcademyRequestRole ADMIN = _$ADMIN;
  @BuiltValueEnumConst(wireName: r'COACH')
  static const AcademyRequestRole COACH = _$COACH;
  @BuiltValueEnumConst(wireName: r'PARENT')
  static const AcademyRequestRole PARENT = _$PARENT;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AcademyRequestRole unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<AcademyRequestRole> get serializer => _$academyRequestRoleSerializer;

  const AcademyRequestRole._(String name): super(name);

  static BuiltSet<AcademyRequestRole> get values => _$values;
  static AcademyRequestRole valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AcademyRequestRoleMixin = Object with _$AcademyRequestRoleMixin;

