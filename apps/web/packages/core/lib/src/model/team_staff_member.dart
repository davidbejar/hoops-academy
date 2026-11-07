//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/staff_role.dart';
import 'package:hoops_core_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_staff_member.g.dart';

/// TeamStaffMember
///
/// Properties:
/// * [person]
/// * [role]
/// * [since]
@BuiltValue()
abstract class TeamStaffMember
    implements Built<TeamStaffMember, TeamStaffMemberBuilder> {
  @BuiltValueField(wireName: r'person')
  PersonRef get person;

  @BuiltValueField(wireName: r'role')
  StaffRole get role;
  // enum roleEnum {  COACH,  ASSISTANT_COACH,  };

  @BuiltValueField(wireName: r'since')
  Date get since;

  TeamStaffMember._();

  factory TeamStaffMember([void updates(TeamStaffMemberBuilder b)]) =
      _$TeamStaffMember;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamStaffMemberBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TeamStaffMember> get serializer =>
      _$TeamStaffMemberSerializer();
}

class _$TeamStaffMemberSerializer
    implements PrimitiveSerializer<TeamStaffMember> {
  @override
  final Iterable<Type> types = const [TeamStaffMember, _$TeamStaffMember];

  @override
  final String wireName = r'TeamStaffMember';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TeamStaffMember object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'person';
    yield serializers.serialize(
      object.person,
      specifiedType: const FullType(PersonRef),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(StaffRole),
    );
    yield r'since';
    yield serializers.serialize(
      object.since,
      specifiedType: const FullType(Date),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TeamStaffMember object, {
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
    required TeamStaffMemberBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'person':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.person.replace(valueDes);
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StaffRole),
          ) as StaffRole;
          result.role = valueDes;
          break;
        case r'since':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.since = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TeamStaffMember deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamStaffMemberBuilder();
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
