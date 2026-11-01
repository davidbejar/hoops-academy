//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/attendance_input.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'record_attendance_request.g.dart';

/// RecordAttendanceRequest
///
/// Properties:
/// * [entries] 
@BuiltValue()
abstract class RecordAttendanceRequest implements Built<RecordAttendanceRequest, RecordAttendanceRequestBuilder> {
  @BuiltValueField(wireName: r'entries')
  BuiltList<AttendanceInput> get entries;

  RecordAttendanceRequest._();

  factory RecordAttendanceRequest([void updates(RecordAttendanceRequestBuilder b)]) = _$RecordAttendanceRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RecordAttendanceRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RecordAttendanceRequest> get serializer => _$RecordAttendanceRequestSerializer();
}

class _$RecordAttendanceRequestSerializer implements PrimitiveSerializer<RecordAttendanceRequest> {
  @override
  final Iterable<Type> types = const [RecordAttendanceRequest, _$RecordAttendanceRequest];

  @override
  final String wireName = r'RecordAttendanceRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RecordAttendanceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [FullType(AttendanceInput)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RecordAttendanceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RecordAttendanceRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AttendanceInput)]),
          ) as BuiltList<AttendanceInput>;
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
  RecordAttendanceRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RecordAttendanceRequestBuilder();
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


