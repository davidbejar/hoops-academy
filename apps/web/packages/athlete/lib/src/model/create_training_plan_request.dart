//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/plan_item_input.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_training_plan_request.g.dart';

/// CreateTrainingPlanRequest
///
/// Properties:
/// * [name] 
/// * [description] 
/// * [items] 
@BuiltValue()
abstract class CreateTrainingPlanRequest implements Built<CreateTrainingPlanRequest, CreateTrainingPlanRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'items')
  BuiltList<PlanItemInput>? get items;

  CreateTrainingPlanRequest._();

  factory CreateTrainingPlanRequest([void updates(CreateTrainingPlanRequestBuilder b)]) = _$CreateTrainingPlanRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTrainingPlanRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTrainingPlanRequest> get serializer => _$CreateTrainingPlanRequestSerializer();
}

class _$CreateTrainingPlanRequestSerializer implements PrimitiveSerializer<CreateTrainingPlanRequest> {
  @override
  final Iterable<Type> types = const [CreateTrainingPlanRequest, _$CreateTrainingPlanRequest];

  @override
  final String wireName = r'CreateTrainingPlanRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTrainingPlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.items != null) {
      yield r'items';
      yield serializers.serialize(
        object.items,
        specifiedType: const FullType(BuiltList, [FullType(PlanItemInput)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTrainingPlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTrainingPlanRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(PlanItemInput)]),
          ) as BuiltList<PlanItemInput>?;
          if (valueDes == null) continue;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTrainingPlanRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTrainingPlanRequestBuilder();
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


