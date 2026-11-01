//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'training_plan_summary.g.dart';

/// TrainingPlanSummary
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [description] 
/// * [template] - Global, read-only template (copy before use).
/// * [sourceTemplateId] - Template (or plan) this plan was copied from.
/// * [itemCount] 
/// * [totalDurationMinutes] 
/// * [archived] - Archived plans are hidden from lists and cannot be assigned (see `archiveTrainingPlan`).
@BuiltValue(instantiable: false)
abstract class TrainingPlanSummary  {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'description')
  String? get description;

  /// Global, read-only template (copy before use).
  @BuiltValueField(wireName: r'template')
  bool get template;

  /// Template (or plan) this plan was copied from.
  @BuiltValueField(wireName: r'sourceTemplateId')
  String? get sourceTemplateId;

  @BuiltValueField(wireName: r'itemCount')
  int get itemCount;

  @BuiltValueField(wireName: r'totalDurationMinutes')
  int get totalDurationMinutes;

  /// Archived plans are hidden from lists and cannot be assigned (see `archiveTrainingPlan`).
  @BuiltValueField(wireName: r'archived')
  bool? get archived;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrainingPlanSummary> get serializer => _$TrainingPlanSummarySerializer();
}

class _$TrainingPlanSummarySerializer implements PrimitiveSerializer<TrainingPlanSummary> {
  @override
  final Iterable<Type> types = const [TrainingPlanSummary];

  @override
  final String wireName = r'TrainingPlanSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrainingPlanSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'template';
    yield serializers.serialize(
      object.template,
      specifiedType: const FullType(bool),
    );
    if (object.sourceTemplateId != null) {
      yield r'sourceTemplateId';
      yield serializers.serialize(
        object.sourceTemplateId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'itemCount';
    yield serializers.serialize(
      object.itemCount,
      specifiedType: const FullType(int),
    );
    yield r'totalDurationMinutes';
    yield serializers.serialize(
      object.totalDurationMinutes,
      specifiedType: const FullType(int),
    );
    if (object.archived != null) {
      yield r'archived';
      yield serializers.serialize(
        object.archived,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TrainingPlanSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  TrainingPlanSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($TrainingPlanSummary)) as $TrainingPlanSummary;
  }
}


/// a concrete implementation of [TrainingPlanSummary], since [TrainingPlanSummary] is not instantiable
@BuiltValue(instantiable: true)
abstract class $TrainingPlanSummary implements TrainingPlanSummary, Built<$TrainingPlanSummary, $TrainingPlanSummaryBuilder> {
  $TrainingPlanSummary._();

  factory $TrainingPlanSummary([void Function($TrainingPlanSummaryBuilder)? updates]) = _$$TrainingPlanSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($TrainingPlanSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$TrainingPlanSummary> get serializer => _$$TrainingPlanSummarySerializer();
}

class _$$TrainingPlanSummarySerializer implements PrimitiveSerializer<$TrainingPlanSummary> {
  @override
  final Iterable<Type> types = const [$TrainingPlanSummary, _$$TrainingPlanSummary];

  @override
  final String wireName = r'$TrainingPlanSummary';

  @override
  Object serialize(
    Serializers serializers,
    $TrainingPlanSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(TrainingPlanSummary))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrainingPlanSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
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
        case r'template':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.template = valueDes;
          break;
        case r'sourceTemplateId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.sourceTemplateId = valueDes;
          break;
        case r'itemCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.itemCount = valueDes;
          break;
        case r'totalDurationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalDurationMinutes = valueDes;
          break;
        case r'archived':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.archived = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  $TrainingPlanSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $TrainingPlanSummaryBuilder();
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

