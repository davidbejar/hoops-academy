//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_exercise_request.g.dart';

/// UpdateExerciseRequest
///
/// Properties:
/// * [title] 
/// * [description] 
/// * [durationMinutes] 
/// * [sets] 
/// * [repetitions] 
/// * [videoUrl] 
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateExerciseRequest implements Built<UpdateExerciseRequest, UpdateExerciseRequestBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'durationMinutes')
  int? get durationMinutes;

  @BuiltValueField(wireName: r'sets')
  int? get sets;

  @BuiltValueField(wireName: r'repetitions')
  int? get repetitions;

  @BuiltValueField(wireName: r'videoUrl')
  String? get videoUrl;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateExerciseRequestClearEnum>? get clear;
  // enum clearEnum {  description,  durationMinutes,  sets,  repetitions,  videoUrl,  };

  UpdateExerciseRequest._();

  factory UpdateExerciseRequest([void updates(UpdateExerciseRequestBuilder b)]) = _$UpdateExerciseRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateExerciseRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateExerciseRequest> get serializer => _$UpdateExerciseRequestSerializer();
}

class _$UpdateExerciseRequestSerializer implements PrimitiveSerializer<UpdateExerciseRequest> {
  @override
  final Iterable<Type> types = const [UpdateExerciseRequest, _$UpdateExerciseRequest];

  @override
  final String wireName = r'UpdateExerciseRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateExerciseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
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
    if (object.durationMinutes != null) {
      yield r'durationMinutes';
      yield serializers.serialize(
        object.durationMinutes,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.sets != null) {
      yield r'sets';
      yield serializers.serialize(
        object.sets,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.repetitions != null) {
      yield r'repetitions';
      yield serializers.serialize(
        object.repetitions,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.videoUrl != null) {
      yield r'videoUrl';
      yield serializers.serialize(
        object.videoUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateExerciseRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateExerciseRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateExerciseRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'durationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.durationMinutes = valueDes;
          break;
        case r'sets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.sets = valueDes;
          break;
        case r'repetitions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.repetitions = valueDes;
          break;
        case r'videoUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.videoUrl = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateExerciseRequestClearEnum)]),
          ) as BuiltSet<UpdateExerciseRequestClearEnum>?;
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
  UpdateExerciseRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateExerciseRequestBuilder();
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


class UpdateExerciseRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'description')
  static const UpdateExerciseRequestClearEnum description = _$updateExerciseRequestClearEnum_description;
  @BuiltValueEnumConst(wireName: r'durationMinutes')
  static const UpdateExerciseRequestClearEnum durationMinutes = _$updateExerciseRequestClearEnum_durationMinutes;
  @BuiltValueEnumConst(wireName: r'sets')
  static const UpdateExerciseRequestClearEnum sets = _$updateExerciseRequestClearEnum_sets;
  @BuiltValueEnumConst(wireName: r'repetitions')
  static const UpdateExerciseRequestClearEnum repetitions = _$updateExerciseRequestClearEnum_repetitions;
  @BuiltValueEnumConst(wireName: r'videoUrl')
  static const UpdateExerciseRequestClearEnum videoUrl = _$updateExerciseRequestClearEnum_videoUrl;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateExerciseRequestClearEnum unknownDefaultOpenApi = _$updateExerciseRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateExerciseRequestClearEnum> get serializer => _$updateExerciseRequestClearEnumSerializer;

  const UpdateExerciseRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateExerciseRequestClearEnum> get values => _$updateExerciseRequestClearEnumValues;
  static UpdateExerciseRequestClearEnum valueOf(String name) => _$updateExerciseRequestClearEnumValueOf(name);
}

