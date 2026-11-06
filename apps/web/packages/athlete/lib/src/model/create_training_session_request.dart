//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_training_session_request.g.dart';

/// CreateTrainingSessionRequest
///
/// Properties:
/// * [teamId] 
/// * [startsAt] 
/// * [durationMinutes] 
/// * [location] 
/// * [planId] - Any plan the academy can read, referenced directly (no assignment needed, 2.3.0): one of its tenant plans (plans are not tied to a team, so a COACH may pick any of them) or a global template; another tenant's or an unknown plan is 404, the ad-hoc plan of another session 422 (`PLAN_OF_ANOTHER_SESSION`). 
/// * [notes] 
@BuiltValue()
abstract class CreateTrainingSessionRequest implements Built<CreateTrainingSessionRequest, CreateTrainingSessionRequestBuilder> {
  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'startsAt')
  DateTime get startsAt;

  @BuiltValueField(wireName: r'durationMinutes')
  int get durationMinutes;

  @BuiltValueField(wireName: r'location')
  String? get location;

  /// Any plan the academy can read, referenced directly (no assignment needed, 2.3.0): one of its tenant plans (plans are not tied to a team, so a COACH may pick any of them) or a global template; another tenant's or an unknown plan is 404, the ad-hoc plan of another session 422 (`PLAN_OF_ANOTHER_SESSION`). 
  @BuiltValueField(wireName: r'planId')
  String? get planId;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  CreateTrainingSessionRequest._();

  factory CreateTrainingSessionRequest([void updates(CreateTrainingSessionRequestBuilder b)]) = _$CreateTrainingSessionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTrainingSessionRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTrainingSessionRequest> get serializer => _$CreateTrainingSessionRequestSerializer();
}

class _$CreateTrainingSessionRequestSerializer implements PrimitiveSerializer<CreateTrainingSessionRequest> {
  @override
  final Iterable<Type> types = const [CreateTrainingSessionRequest, _$CreateTrainingSessionRequest];

  @override
  final String wireName = r'CreateTrainingSessionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTrainingSessionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'startsAt';
    yield serializers.serialize(
      object.startsAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'durationMinutes';
    yield serializers.serialize(
      object.durationMinutes,
      specifiedType: const FullType(int),
    );
    if (object.location != null) {
      yield r'location';
      yield serializers.serialize(
        object.location,
        specifiedType: const FullType(String),
      );
    }
    if (object.planId != null) {
      yield r'planId';
      yield serializers.serialize(
        object.planId,
        specifiedType: const FullType(String),
      );
    }
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
    CreateTrainingSessionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTrainingSessionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'startsAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startsAt = valueDes;
          break;
        case r'durationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTrainingSessionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTrainingSessionRequestBuilder();
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


