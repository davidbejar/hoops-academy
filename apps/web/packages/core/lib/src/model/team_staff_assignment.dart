//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/staff_role.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_staff_assignment.g.dart';

/// TeamStaffAssignment
///
/// Properties:
/// * [role]
@BuiltValue()
abstract class TeamStaffAssignment
    implements Built<TeamStaffAssignment, TeamStaffAssignmentBuilder> {
  @BuiltValueField(wireName: r'role')
  StaffRole get role;
  // enum roleEnum {  COACH,  ASSISTANT_COACH,  };

  TeamStaffAssignment._();

  factory TeamStaffAssignment([void updates(TeamStaffAssignmentBuilder b)]) =
      _$TeamStaffAssignment;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamStaffAssignmentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TeamStaffAssignment> get serializer =>
      _$TeamStaffAssignmentSerializer();
}

class _$TeamStaffAssignmentSerializer
    implements PrimitiveSerializer<TeamStaffAssignment> {
  @override
  final Iterable<Type> types = const [
    TeamStaffAssignment,
    _$TeamStaffAssignment
  ];

  @override
  final String wireName = r'TeamStaffAssignment';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TeamStaffAssignment object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(StaffRole),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TeamStaffAssignment object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TeamStaffAssignmentBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StaffRole),
          ) as StaffRole;
          result.role = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TeamStaffAssignment deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamStaffAssignmentBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
