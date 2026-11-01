//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/attendance_status.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'attendance_entry.g.dart';

/// AttendanceEntry
///
/// Properties:
/// * [playerId] 
/// * [status] - Null = not recorded yet.
/// * [minutesLate] 
/// * [note] 
/// * [expectedAbsent] - A planned absence covers the session date.
/// * [plannedAbsenceId] 
/// * [unavailableInjuryId] - Set when the player has an OPEN injury.
/// * [recordedBy] 
/// * [recordedAt] 
@BuiltValue()
abstract class AttendanceEntry implements Built<AttendanceEntry, AttendanceEntryBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  /// Null = not recorded yet.
  @BuiltValueField(wireName: r'status')
  AttendanceStatus? get status;
  // enum statusEnum {  PRESENT,  LATE,  ABSENT,  EXCUSED,  };

  @BuiltValueField(wireName: r'minutesLate')
  int? get minutesLate;

  @BuiltValueField(wireName: r'note')
  String? get note;

  /// A planned absence covers the session date.
  @BuiltValueField(wireName: r'expectedAbsent')
  bool get expectedAbsent;

  @BuiltValueField(wireName: r'plannedAbsenceId')
  String? get plannedAbsenceId;

  /// Set when the player has an OPEN injury.
  @BuiltValueField(wireName: r'unavailableInjuryId')
  String? get unavailableInjuryId;

  @BuiltValueField(wireName: r'recordedBy')
  PersonRef? get recordedBy;

  @BuiltValueField(wireName: r'recordedAt')
  DateTime? get recordedAt;

  AttendanceEntry._();

  factory AttendanceEntry([void updates(AttendanceEntryBuilder b)]) = _$AttendanceEntry;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AttendanceEntryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AttendanceEntry> get serializer => _$AttendanceEntrySerializer();
}

class _$AttendanceEntrySerializer implements PrimitiveSerializer<AttendanceEntry> {
  @override
  final Iterable<Type> types = const [AttendanceEntry, _$AttendanceEntry];

  @override
  final String wireName = r'AttendanceEntry';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AttendanceEntry object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(AttendanceStatus),
      );
    }
    if (object.minutesLate != null) {
      yield r'minutesLate';
      yield serializers.serialize(
        object.minutesLate,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'expectedAbsent';
    yield serializers.serialize(
      object.expectedAbsent,
      specifiedType: const FullType(bool),
    );
    if (object.plannedAbsenceId != null) {
      yield r'plannedAbsenceId';
      yield serializers.serialize(
        object.plannedAbsenceId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.unavailableInjuryId != null) {
      yield r'unavailableInjuryId';
      yield serializers.serialize(
        object.unavailableInjuryId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.recordedBy != null) {
      yield r'recordedBy';
      yield serializers.serialize(
        object.recordedBy,
        specifiedType: const FullType.nullable(PersonRef),
      );
    }
    if (object.recordedAt != null) {
      yield r'recordedAt';
      yield serializers.serialize(
        object.recordedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AttendanceEntry object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AttendanceEntryBuilder result,
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
            specifiedType: const FullType.nullable(AttendanceStatus),
          ) as AttendanceStatus?;
          if (valueDes == null) continue;
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
        case r'expectedAbsent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.expectedAbsent = valueDes;
          break;
        case r'plannedAbsenceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.plannedAbsenceId = valueDes;
          break;
        case r'unavailableInjuryId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.unavailableInjuryId = valueDes;
          break;
        case r'recordedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PersonRef),
          ) as PersonRef?;
          if (valueDes == null) continue;
          result.recordedBy.replace(valueDes);
          break;
        case r'recordedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.recordedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AttendanceEntry deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AttendanceEntryBuilder();
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


