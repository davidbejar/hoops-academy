//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_training_plan_request.g.dart';

/// UpdateTrainingPlanRequest
///
/// Properties:
/// * [name]
/// * [description]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateTrainingPlanRequest implements Built<UpdateTrainingPlanRequest, UpdateTrainingPlanRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'description')
  String? get description;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateTrainingPlanRequestClearEnum>? get clear;
  // enum clearEnum {  description,  };

  UpdateTrainingPlanRequest._();

  factory UpdateTrainingPlanRequest([void updates(UpdateTrainingPlanRequestBuilder b)]) = _$UpdateTrainingPlanRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTrainingPlanRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTrainingPlanRequest> get serializer => _$UpdateTrainingPlanRequestSerializer();
}

class _$UpdateTrainingPlanRequestSerializer implements PrimitiveSerializer<UpdateTrainingPlanRequest> {
  @override
  final Iterable<Type> types = const [UpdateTrainingPlanRequest, _$UpdateTrainingPlanRequest];

  @override
  final String wireName = r'UpdateTrainingPlanRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTrainingPlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateTrainingPlanRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTrainingPlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTrainingPlanRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateTrainingPlanRequestClearEnum)]),
          ) as BuiltSet<UpdateTrainingPlanRequestClearEnum>?;
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
  UpdateTrainingPlanRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTrainingPlanRequestBuilder();
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


class UpdateTrainingPlanRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'description')
  static const UpdateTrainingPlanRequestClearEnum description = _$updateTrainingPlanRequestClearEnum_description;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTrainingPlanRequestClearEnum unknownDefaultOpenApi = _$updateTrainingPlanRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTrainingPlanRequestClearEnum> get serializer => _$updateTrainingPlanRequestClearEnumSerializer;

  const UpdateTrainingPlanRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateTrainingPlanRequestClearEnum> get values => _$updateTrainingPlanRequestClearEnumValues;
  static UpdateTrainingPlanRequestClearEnum valueOf(String name) => _$updateTrainingPlanRequestClearEnumValueOf(name);
}
