//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_training_session_request.g.dart';

/// UpdateTrainingSessionRequest
///
/// Properties:
/// * [startsAt] 
/// * [durationMinutes] 
/// * [location] 
/// * [planId] - As in `CreateTrainingSessionRequest`. Moving the session off its ad-hoc plan (another plan, or `clear`) deletes that plan with its items (2.3.0). 
/// * [notes] 
/// * [status] - PLANNED ↔ DONE; use the cancel operation to cancel.
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateTrainingSessionRequest implements Built<UpdateTrainingSessionRequest, UpdateTrainingSessionRequestBuilder> {
  @BuiltValueField(wireName: r'startsAt')
  DateTime? get startsAt;

  @BuiltValueField(wireName: r'durationMinutes')
  int? get durationMinutes;

  @BuiltValueField(wireName: r'location')
  String? get location;

  /// As in `CreateTrainingSessionRequest`. Moving the session off its ad-hoc plan (another plan, or `clear`) deletes that plan with its items (2.3.0). 
  @BuiltValueField(wireName: r'planId')
  String? get planId;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  /// PLANNED ↔ DONE; use the cancel operation to cancel.
  @BuiltValueField(wireName: r'status')
  UpdateTrainingSessionRequestStatusEnum? get status;
  // enum statusEnum {  PLANNED,  DONE,  };

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateTrainingSessionRequestClearEnum>? get clear;
  // enum clearEnum {  location,  planId,  notes,  };

  UpdateTrainingSessionRequest._();

  factory UpdateTrainingSessionRequest([void updates(UpdateTrainingSessionRequestBuilder b)]) = _$UpdateTrainingSessionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTrainingSessionRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTrainingSessionRequest> get serializer => _$UpdateTrainingSessionRequestSerializer();
}

class _$UpdateTrainingSessionRequestSerializer implements PrimitiveSerializer<UpdateTrainingSessionRequest> {
  @override
  final Iterable<Type> types = const [UpdateTrainingSessionRequest, _$UpdateTrainingSessionRequest];

  @override
  final String wireName = r'UpdateTrainingSessionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTrainingSessionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.startsAt != null) {
      yield r'startsAt';
      yield serializers.serialize(
        object.startsAt,
        specifiedType: const FullType(DateTime),
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
    if (object.planId != null) {
      yield r'planId';
      yield serializers.serialize(
        object.planId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.notes != null) {
      yield r'notes';
      yield serializers.serialize(
        object.notes,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(UpdateTrainingSessionRequestStatusEnum),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateTrainingSessionRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTrainingSessionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTrainingSessionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'startsAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.startsAt = valueDes;
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
        case r'planId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.planId = valueDes;
          break;
        case r'notes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.notes = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(UpdateTrainingSessionRequestStatusEnum),
          ) as UpdateTrainingSessionRequestStatusEnum?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateTrainingSessionRequestClearEnum)]),
          ) as BuiltSet<UpdateTrainingSessionRequestClearEnum>?;
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
  UpdateTrainingSessionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTrainingSessionRequestBuilder();
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


/// PLANNED ↔ DONE; use the cancel operation to cancel.
class UpdateTrainingSessionRequestStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PLANNED')
  static const UpdateTrainingSessionRequestStatusEnum PLANNED = _$updateTrainingSessionRequestStatusEnum_PLANNED;
  @BuiltValueEnumConst(wireName: r'DONE')
  static const UpdateTrainingSessionRequestStatusEnum DONE = _$updateTrainingSessionRequestStatusEnum_DONE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTrainingSessionRequestStatusEnum unknownDefaultOpenApi = _$updateTrainingSessionRequestStatusEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTrainingSessionRequestStatusEnum> get serializer => _$updateTrainingSessionRequestStatusEnumSerializer;

  const UpdateTrainingSessionRequestStatusEnum._(String name): super(name);

  static BuiltSet<UpdateTrainingSessionRequestStatusEnum> get values => _$updateTrainingSessionRequestStatusEnumValues;
  static UpdateTrainingSessionRequestStatusEnum valueOf(String name) => _$updateTrainingSessionRequestStatusEnumValueOf(name);
}

class UpdateTrainingSessionRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'location')
  static const UpdateTrainingSessionRequestClearEnum location = _$updateTrainingSessionRequestClearEnum_location;
  @BuiltValueEnumConst(wireName: r'planId')
  static const UpdateTrainingSessionRequestClearEnum planId = _$updateTrainingSessionRequestClearEnum_planId;
  @BuiltValueEnumConst(wireName: r'notes')
  static const UpdateTrainingSessionRequestClearEnum notes = _$updateTrainingSessionRequestClearEnum_notes;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTrainingSessionRequestClearEnum unknownDefaultOpenApi = _$updateTrainingSessionRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTrainingSessionRequestClearEnum> get serializer => _$updateTrainingSessionRequestClearEnumSerializer;

  const UpdateTrainingSessionRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateTrainingSessionRequestClearEnum> get values => _$updateTrainingSessionRequestClearEnumValues;
  static UpdateTrainingSessionRequestClearEnum valueOf(String name) => _$updateTrainingSessionRequestClearEnumValueOf(name);
}

