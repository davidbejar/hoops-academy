//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/plan_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'training_plan.g.dart';

/// TrainingPlan
///
/// Properties:
/// * [id] 
/// * [name] - Templates in the negotiated language (`Accept-Language`, fallback `en`); tenant plans as stored.
/// * [nameKey] - Stable key of a global template's texts (e.g. `form-shooting`), the same in every language; null for tenant plans (copies included).
/// * [description] - Same language rule as `name`.
/// * [template] - Global, read-only template (copy before use).
/// * [sourceTemplateId] - Template (or plan) this plan was copied from.
/// * [itemCount] 
/// * [totalDurationMinutes] 
/// * [archived] - Archived plans are hidden from lists and cannot be assigned (see `archiveTrainingPlan`).
/// * [sessionId] - Set on the ad-hoc plan of a session (created by `copyItemsToSession`, 2.3.0): the plan belongs to that session, is not listed and cannot be assigned or attached to another session. 
/// * [items] 
@BuiltValue()
abstract class TrainingPlan implements Built<TrainingPlan, TrainingPlanBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Templates in the negotiated language (`Accept-Language`, fallback `en`); tenant plans as stored.
  @BuiltValueField(wireName: r'name')
  String get name;

  /// Stable key of a global template's texts (e.g. `form-shooting`), the same in every language; null for tenant plans (copies included).
  @BuiltValueField(wireName: r'nameKey')
  String? get nameKey;

  /// Same language rule as `name`.
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

  /// Set on the ad-hoc plan of a session (created by `copyItemsToSession`, 2.3.0): the plan belongs to that session, is not listed and cannot be assigned or attached to another session. 
  @BuiltValueField(wireName: r'sessionId')
  String? get sessionId;

  @BuiltValueField(wireName: r'items')
  BuiltList<PlanItem> get items;

  TrainingPlan._();

  factory TrainingPlan([void updates(TrainingPlanBuilder b)]) = _$TrainingPlan;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrainingPlanBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrainingPlan> get serializer => _$TrainingPlanSerializer();
}

class _$TrainingPlanSerializer implements PrimitiveSerializer<TrainingPlan> {
  @override
  final Iterable<Type> types = const [TrainingPlan, _$TrainingPlan];

  @override
  final String wireName = r'TrainingPlan';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrainingPlan object, {
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
    if (object.nameKey != null) {
      yield r'nameKey';
      yield serializers.serialize(
        object.nameKey,
        specifiedType: const FullType.nullable(String),
      );
    }
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
    if (object.sessionId != null) {
      yield r'sessionId';
      yield serializers.serialize(
        object.sessionId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(PlanItem)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TrainingPlan object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrainingPlanBuilder result,
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
        case r'nameKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nameKey = valueDes;
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
        case r'sessionId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.sessionId = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlanItem)]),
          ) as BuiltList<PlanItem>;
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
  TrainingPlan deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrainingPlanBuilder();
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


