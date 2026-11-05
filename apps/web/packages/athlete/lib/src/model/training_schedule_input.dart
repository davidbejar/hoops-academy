//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/day_of_week.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'training_schedule_input.g.dart';

/// TrainingScheduleInput
///
/// Properties:
/// * [teamId]
/// * [dayOfWeek]
/// * [startTime] - Wall-clock time in the tenant's time zone, `HH:mm`.
/// * [durationMinutes]
/// * [location]
/// * [validFrom]
/// * [validUntil] - Inclusive; absent = open-ended.
@BuiltValue()
abstract class TrainingScheduleInput implements Built<TrainingScheduleInput, TrainingScheduleInputBuilder> {
  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'dayOfWeek')
  DayOfWeek get dayOfWeek;
  // enum dayOfWeekEnum {  MONDAY,  TUESDAY,  WEDNESDAY,  THURSDAY,  FRIDAY,  SATURDAY,  SUNDAY,  };

  /// Wall-clock time in the tenant's time zone, `HH:mm`.
  @BuiltValueField(wireName: r'startTime')
  String get startTime;

  @BuiltValueField(wireName: r'durationMinutes')
  int get durationMinutes;

  @BuiltValueField(wireName: r'location')
  String? get location;

  @BuiltValueField(wireName: r'validFrom')
  Date get validFrom;

  /// Inclusive; absent = open-ended.
  @BuiltValueField(wireName: r'validUntil')
  Date? get validUntil;

  TrainingScheduleInput._();

  factory TrainingScheduleInput([void updates(TrainingScheduleInputBuilder b)]) = _$TrainingScheduleInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrainingScheduleInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrainingScheduleInput> get serializer => _$TrainingScheduleInputSerializer();
}

class _$TrainingScheduleInputSerializer implements PrimitiveSerializer<TrainingScheduleInput> {
  @override
  final Iterable<Type> types = const [TrainingScheduleInput, _$TrainingScheduleInput];

  @override
  final String wireName = r'TrainingScheduleInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrainingScheduleInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'dayOfWeek';
    yield serializers.serialize(
      object.dayOfWeek,
      specifiedType: const FullType(DayOfWeek),
    );
    yield r'startTime';
    yield serializers.serialize(
      object.startTime,
      specifiedType: const FullType(String),
    );
    yield r'durationMinutes';
    yield serializers.serialize(
      object.durationMinutes,
      specifiedType: const FullType(int),
    );
    if (object.location != null) {
      yield r'location';
      yield serializers.serialize(
        object.location,
        specifiedType: const FullType(String),
      );
    }
    yield r'validFrom';
    yield serializers.serialize(
      object.validFrom,
      specifiedType: const FullType(Date),
    );
    if (object.validUntil != null) {
      yield r'validUntil';
      yield serializers.serialize(
        object.validUntil,
        specifiedType: const FullType(Date),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TrainingScheduleInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrainingScheduleInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'dayOfWeek':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DayOfWeek),
          ) as DayOfWeek;
          result.dayOfWeek = valueDes;
          break;
        case r'startTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startTime = valueDes;
          break;
        case r'durationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.durationMinutes = valueDes;
          break;
        case r'location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.location = valueDes;
          break;
        case r'validFrom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.validFrom = valueDes;
          break;
        case r'validUntil':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.validUntil = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TrainingScheduleInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrainingScheduleInputBuilder();
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
