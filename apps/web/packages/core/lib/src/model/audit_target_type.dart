//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_target_type.g.dart';

class AuditTargetType extends EnumClass {
  @BuiltValueEnumConst(wireName: r'person')
  static const AuditTargetType person = _$person;
  @BuiltValueEnumConst(wireName: r'player')
  static const AuditTargetType player = _$player;
  @BuiltValueEnumConst(wireName: r'tenant')
  static const AuditTargetType tenant = _$tenant;
  @BuiltValueEnumConst(wireName: r'approval_request')
  static const AuditTargetType approvalRequest = _$approvalRequest;
  @BuiltValueEnumConst(wireName: r'guardian_link')
  static const AuditTargetType guardianLink = _$guardianLink;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AuditTargetType unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<AuditTargetType> get serializer =>
      _$auditTargetTypeSerializer;

  const AuditTargetType._(String name) : super(name);

  static BuiltSet<AuditTargetType> get values => _$values;
  static AuditTargetType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AuditTargetTypeMixin = Object with _$AuditTargetTypeMixin;
