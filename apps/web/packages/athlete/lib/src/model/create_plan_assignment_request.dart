//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_plan_assignment_request.g.dart';

/// Exactly one of `teamId` / `playerId`.
///
/// Properties:
/// * [planId] 
/// * [teamId] 
/// * [playerId] 
/// * [dueOn] 
/// * [notes] 
@BuiltValue()
abstract class CreatePlanAssignmentRequest implements Built<CreatePlanAssignmentRequest, CreatePlanAssignmentRequestBuilder> {
  @BuiltValueField(wireName: r'planId')
  String get planId;

  @BuiltValueField(wireName: r'teamId')
  String? get teamId;

  @BuiltValueField(wireName: r'playerId')
  String? get playerId;

  @BuiltValueField(wireName: r'dueOn')
  Date get dueOn;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  CreatePlanAssignmentRequest._();

  factory CreatePlanAssignmentRequest([void updates(CreatePlanAssignmentRequestBuilder b)]) = _$CreatePlanAssignmentRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreatePlanAssignmentRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreatePlanAssignmentRequest> get serializer => _$CreatePlanAssignmentRequestSerializer();
}

class _$CreatePlanAssignmentRequestSerializer implements PrimitiveSerializer<CreatePlanAssignmentRequest> {
  @override
  final Iterable<Type> types = const [CreatePlanAssignmentRequest, _$CreatePlanAssignmentRequest];

  @override
  final String wireName = r'CreatePlanAssignmentRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreatePlanAssignmentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'planId';
    yield serializers.serialize(
      object.planId,
      specifiedType: const FullType(String),
    );
    if (object.teamId != null) {
      yield r'teamId';
      yield serializers.serialize(
        object.teamId,
        specifiedType: const FullType(String),
      );
    }
    if (object.playerId != null) {
      yield r'playerId';
      yield serializers.serialize(
        object.playerId,
        specifiedType: const FullType(String),
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
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreatePlanAssignmentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreatePlanAssignmentRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'planId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.planId = valueDes;
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
  CreatePlanAssignmentRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreatePlanAssignmentRequestBuilder();
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


