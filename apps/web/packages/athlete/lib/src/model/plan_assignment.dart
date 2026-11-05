//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/training_plan_summary.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_assignment.g.dart';

/// PlanAssignment
///
/// Properties:
/// * [recordedBy]
/// * [recordedAt]
/// * [id]
/// * [plan]
/// * [teamId]
/// * [playerId]
/// * [dueOn]
/// * [notes]
@BuiltValue()
abstract class PlanAssignment implements Built<PlanAssignment, PlanAssignmentBuilder> {
  @BuiltValueField(wireName: r'recordedBy')
  PersonRef get recordedBy;

  @BuiltValueField(wireName: r'recordedAt')
  DateTime get recordedAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'plan')
  TrainingPlanSummary get plan;

  @BuiltValueField(wireName: r'teamId')
  String? get teamId;

  @BuiltValueField(wireName: r'playerId')
  String? get playerId;

  @BuiltValueField(wireName: r'dueOn')
  Date get dueOn;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  PlanAssignment._();

  factory PlanAssignment([void updates(PlanAssignmentBuilder b)]) = _$PlanAssignment;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanAssignmentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanAssignment> get serializer => _$PlanAssignmentSerializer();
}

class _$PlanAssignmentSerializer implements PrimitiveSerializer<PlanAssignment> {
  @override
  final Iterable<Type> types = const [PlanAssignment, _$PlanAssignment];

  @override
  final String wireName = r'PlanAssignment';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanAssignment object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'recordedBy';
    yield serializers.serialize(
      object.recordedBy,
      specifiedType: const FullType(PersonRef),
    );
    yield r'recordedAt';
    yield serializers.serialize(
      object.recordedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'plan';
    yield serializers.serialize(
      object.plan,
      specifiedType: const FullType(TrainingPlanSummary),
    );
    if (object.teamId != null) {
      yield r'teamId';
      yield serializers.serialize(
        object.teamId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.playerId != null) {
      yield r'playerId';
      yield serializers.serialize(
        object.playerId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'dueOn';
    yield serializers.serialize(
      object.dueOn,
      specifiedType: const FullType(Date),
    );
    if (object.notes != null) {
      yield r'notes';
      yield serializers.serialize(
        object.notes,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanAssignment object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanAssignmentBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'recordedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.recordedBy.replace(valueDes);
          break;
        case r'recordedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.recordedAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'plan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TrainingPlanSummary),
          ) as TrainingPlanSummary;
          result.plan.replace(valueDes);
          break;
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.teamId = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.playerId = valueDes;
          break;
        case r'dueOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.dueOn = valueDes;
          break;
        case r'notes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.notes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanAssignment deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanAssignmentBuilder();
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
