//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/staff_role.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'roster_staff.g.dart';

/// RosterStaff
///
/// Properties:
/// * [personId] 
/// * [role] 
@BuiltValue()
abstract class RosterStaff implements Built<RosterStaff, RosterStaffBuilder> {
  @BuiltValueField(wireName: r'personId')
  String get personId;

  @BuiltValueField(wireName: r'role')
  StaffRole get role;
  // enum roleEnum {  COACH,  ASSISTANT_COACH,  };

  RosterStaff._();

  factory RosterStaff([void updates(RosterStaffBuilder b)]) = _$RosterStaff;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RosterStaffBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RosterStaff> get serializer => _$RosterStaffSerializer();
}

class _$RosterStaffSerializer implements PrimitiveSerializer<RosterStaff> {
  @override
  final Iterable<Type> types = const [RosterStaff, _$RosterStaff];

  @override
  final String wireName = r'RosterStaff';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RosterStaff object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'personId';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(StaffRole),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RosterStaff object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RosterStaffBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
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
  RosterStaff deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RosterStaffBuilder();
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


