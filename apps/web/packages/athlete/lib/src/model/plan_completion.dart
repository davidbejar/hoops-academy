//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/completion_status.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:hoops_athlete_api/src/model/audit_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_completion.g.dart';

/// PlanCompletion
///
/// Properties:
/// * [recordedBy] 
/// * [recordedAt] 
/// * [id] 
/// * [assignmentId] 
/// * [playerId] 
/// * [status] 
/// * [comment] 
@BuiltValue()
abstract class PlanCompletion implements AuditInfo, Built<PlanCompletion, PlanCompletionBuilder> {
  @BuiltValueField(wireName: r'comment')
  String? get comment;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'assignmentId')
  String get assignmentId;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'status')
  CompletionStatus get status;
  // enum statusEnum {  DONE,  PARTIAL,  NOT_DONE,  };

  PlanCompletion._();

  factory PlanCompletion([void updates(PlanCompletionBuilder b)]) = _$PlanCompletion;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanCompletionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanCompletion> get serializer => _$PlanCompletionSerializer();
}

class _$PlanCompletionSerializer implements PrimitiveSerializer<PlanCompletion> {
  @override
  final Iterable<Type> types = const [PlanCompletion, _$PlanCompletion];

  @override
  final String wireName = r'PlanCompletion';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanCompletion object, {
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
    if (object.comment != null) {
      yield r'comment';
      yield serializers.serialize(
        object.comment,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'assignmentId';
    yield serializers.serialize(
      object.assignmentId,
      specifiedType: const FullType(String),
    );
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CompletionStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanCompletion object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanCompletionBuilder result,
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
        case r'comment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.comment = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'assignmentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assignmentId = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CompletionStatus),
          ) as CompletionStatus;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanCompletion deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanCompletionBuilder();
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


