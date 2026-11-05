//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_item_input.g.dart';

/// PlanItemInput
///
/// Properties:
/// * [title]
/// * [description]
/// * [durationMinutes]
/// * [sets]
/// * [repetitions]
/// * [videoUrl]
@BuiltValue()
abstract class PlanItemInput implements Built<PlanItemInput, PlanItemInputBuilder> {
  @BuiltValueField(wireName: r'title')
  String get title;

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

  PlanItemInput._();

  factory PlanItemInput([void updates(PlanItemInputBuilder b)]) = _$PlanItemInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanItemInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanItemInput> get serializer => _$PlanItemInputSerializer();
}

class _$PlanItemInputSerializer implements PrimitiveSerializer<PlanItemInput> {
  @override
  final Iterable<Type> types = const [PlanItemInput, _$PlanItemInput];

  @override
  final String wireName = r'PlanItemInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanItemInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
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
    if (object.sets != null) {
      yield r'sets';
      yield serializers.serialize(
        object.sets,
        specifiedType: const FullType(int),
      );
    }
    if (object.repetitions != null) {
      yield r'repetitions';
      yield serializers.serialize(
        object.repetitions,
        specifiedType: const FullType(int),
      );
    }
    if (object.videoUrl != null) {
      yield r'videoUrl';
      yield serializers.serialize(
        object.videoUrl,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanItemInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanItemInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanItemInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanItemInputBuilder();
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
