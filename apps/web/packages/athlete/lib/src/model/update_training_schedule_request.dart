//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/day_of_week.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_training_schedule_request.g.dart';

/// UpdateTrainingScheduleRequest
///
/// Properties:
/// * [dayOfWeek]
/// * [startTime] - Wall-clock time in the tenant's time zone, `HH:mm`.
/// * [durationMinutes]
/// * [location]
/// * [validFrom]
/// * [validUntil]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateTrainingScheduleRequest implements Built<UpdateTrainingScheduleRequest, UpdateTrainingScheduleRequestBuilder> {
  @BuiltValueField(wireName: r'dayOfWeek')
  DayOfWeek? get dayOfWeek;
  // enum dayOfWeekEnum {  MONDAY,  TUESDAY,  WEDNESDAY,  THURSDAY,  FRIDAY,  SATURDAY,  SUNDAY,  };

  /// Wall-clock time in the tenant's time zone, `HH:mm`.
  @BuiltValueField(wireName: r'startTime')
  String? get startTime;

  @BuiltValueField(wireName: r'durationMinutes')
  int? get durationMinutes;

  @BuiltValueField(wireName: r'location')
  String? get location;

  @BuiltValueField(wireName: r'validFrom')
  Date? get validFrom;

  @BuiltValueField(wireName: r'validUntil')
  Date? get validUntil;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateTrainingScheduleRequestClearEnum>? get clear;
  // enum clearEnum {  location,  validUntil,  };

  UpdateTrainingScheduleRequest._();

  factory UpdateTrainingScheduleRequest([void updates(UpdateTrainingScheduleRequestBuilder b)]) = _$UpdateTrainingScheduleRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTrainingScheduleRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTrainingScheduleRequest> get serializer => _$UpdateTrainingScheduleRequestSerializer();
}

class _$UpdateTrainingScheduleRequestSerializer implements PrimitiveSerializer<UpdateTrainingScheduleRequest> {
  @override
  final Iterable<Type> types = const [UpdateTrainingScheduleRequest, _$UpdateTrainingScheduleRequest];

  @override
  final String wireName = r'UpdateTrainingScheduleRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTrainingScheduleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.dayOfWeek != null) {
      yield r'dayOfWeek';
      yield serializers.serialize(
        object.dayOfWeek,
        specifiedType: const FullType(DayOfWeek),
      );
    }
    if (object.startTime != null) {
      yield r'startTime';
      yield serializers.serialize(
        object.startTime,
        specifiedType: const FullType(String),
      );
    }
    if (object.durationMinutes != null) {
      yield r'durationMinutes';
      yield serializers.serialize(
        object.durationMinutes,
        specifiedType: const FullType(int),
      );
    }
    if (object.location != null) {
      yield r'location';
      yield serializers.serialize(
        object.location,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.validFrom != null) {
      yield r'validFrom';
      yield serializers.serialize(
        object.validFrom,
        specifiedType: const FullType(Date),
      );
    }
    if (object.validUntil != null) {
      yield r'validUntil';
      yield serializers.serialize(
        object.validUntil,
        specifiedType: const FullType.nullable(Date),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateTrainingScheduleRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTrainingScheduleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTrainingScheduleRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'dayOfWeek':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DayOfWeek),
          ) as DayOfWeek?;
          if (valueDes == null) continue;
          result.dayOfWeek = valueDes;
          break;
        case r'startTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.startTime = valueDes;
          break;
        case r'durationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
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
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateTrainingScheduleRequestClearEnum)]),
          ) as BuiltSet<UpdateTrainingScheduleRequestClearEnum>?;
          if (valueDes == null) continue;
          result.clear.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTrainingScheduleRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTrainingScheduleRequestBuilder();
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


class UpdateTrainingScheduleRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'location')
  static const UpdateTrainingScheduleRequestClearEnum location = _$updateTrainingScheduleRequestClearEnum_location;
  @BuiltValueEnumConst(wireName: r'validUntil')
  static const UpdateTrainingScheduleRequestClearEnum validUntil = _$updateTrainingScheduleRequestClearEnum_validUntil;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTrainingScheduleRequestClearEnum unknownDefaultOpenApi = _$updateTrainingScheduleRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTrainingScheduleRequestClearEnum> get serializer => _$updateTrainingScheduleRequestClearEnumSerializer;

  const UpdateTrainingScheduleRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateTrainingScheduleRequestClearEnum> get values => _$updateTrainingScheduleRequestClearEnumValues;
  static UpdateTrainingScheduleRequestClearEnum valueOf(String name) => _$updateTrainingScheduleRequestClearEnumValueOf(name);
}
