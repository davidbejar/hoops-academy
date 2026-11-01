//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/attendance_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'attendance_input.g.dart';

/// AttendanceInput
///
/// Properties:
/// * [playerId] 
/// * [status] 
/// * [minutesLate] - Required iff status = LATE.
/// * [note] 
@BuiltValue()
abstract class AttendanceInput implements Built<AttendanceInput, AttendanceInputBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'status')
  AttendanceStatus get status;
  // enum statusEnum {  PRESENT,  LATE,  ABSENT,  EXCUSED,  };

  /// Required iff status = LATE.
  @BuiltValueField(wireName: r'minutesLate')
  int? get minutesLate;

  @BuiltValueField(wireName: r'note')
  String? get note;

  AttendanceInput._();

  factory AttendanceInput([void updates(AttendanceInputBuilder b)]) = _$AttendanceInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AttendanceInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AttendanceInput> get serializer => _$AttendanceInputSerializer();
}

class _$AttendanceInputSerializer implements PrimitiveSerializer<AttendanceInput> {
  @override
  final Iterable<Type> types = const [AttendanceInput, _$AttendanceInput];

  @override
  final String wireName = r'AttendanceInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AttendanceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(AttendanceStatus),
    );
    if (object.minutesLate != null) {
      yield r'minutesLate';
      yield serializers.serialize(
        object.minutesLate,
        specifiedType: const FullType(int),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AttendanceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AttendanceInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AttendanceStatus),
          ) as AttendanceStatus;
          result.status = valueDes;
          break;
        case r'minutesLate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.minutesLate = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AttendanceInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AttendanceInputBuilder();
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


