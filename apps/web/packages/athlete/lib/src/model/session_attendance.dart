//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/attendance_entry.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_attendance.g.dart';

/// SessionAttendance
///
/// Properties:
/// * [sessionId] 
/// * [entries] 
@BuiltValue()
abstract class SessionAttendance implements Built<SessionAttendance, SessionAttendanceBuilder> {
  @BuiltValueField(wireName: r'sessionId')
  String get sessionId;

  @BuiltValueField(wireName: r'entries')
  BuiltList<AttendanceEntry> get entries;

  SessionAttendance._();

  factory SessionAttendance([void updates(SessionAttendanceBuilder b)]) = _$SessionAttendance;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionAttendanceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionAttendance> get serializer => _$SessionAttendanceSerializer();
}

class _$SessionAttendanceSerializer implements PrimitiveSerializer<SessionAttendance> {
  @override
  final Iterable<Type> types = const [SessionAttendance, _$SessionAttendance];

  @override
  final String wireName = r'SessionAttendance';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionAttendance object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'sessionId';
    yield serializers.serialize(
      object.sessionId,
      specifiedType: const FullType(String),
    );
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [FullType(AttendanceEntry)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionAttendance object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionAttendanceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'sessionId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sessionId = valueDes;
          break;
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AttendanceEntry)]),
          ) as BuiltList<AttendanceEntry>;
          result.entries.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionAttendance deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionAttendanceBuilder();
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


