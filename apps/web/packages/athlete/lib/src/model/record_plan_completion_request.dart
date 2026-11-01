//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/completion_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'record_plan_completion_request.g.dart';

/// RecordPlanCompletionRequest
///
/// Properties:
/// * [status] 
/// * [comment] 
@BuiltValue()
abstract class RecordPlanCompletionRequest implements Built<RecordPlanCompletionRequest, RecordPlanCompletionRequestBuilder> {
  @BuiltValueField(wireName: r'status')
  CompletionStatus get status;
  // enum statusEnum {  DONE,  PARTIAL,  NOT_DONE,  };

  @BuiltValueField(wireName: r'comment')
  String? get comment;

  RecordPlanCompletionRequest._();

  factory RecordPlanCompletionRequest([void updates(RecordPlanCompletionRequestBuilder b)]) = _$RecordPlanCompletionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RecordPlanCompletionRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RecordPlanCompletionRequest> get serializer => _$RecordPlanCompletionRequestSerializer();
}

class _$RecordPlanCompletionRequestSerializer implements PrimitiveSerializer<RecordPlanCompletionRequest> {
  @override
  final Iterable<Type> types = const [RecordPlanCompletionRequest, _$RecordPlanCompletionRequest];

  @override
  final String wireName = r'RecordPlanCompletionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RecordPlanCompletionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CompletionStatus),
    );
    if (object.comment != null) {
      yield r'comment';
      yield serializers.serialize(
        object.comment,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RecordPlanCompletionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RecordPlanCompletionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CompletionStatus),
          ) as CompletionStatus;
          result.status = valueDes;
          break;
        case r'comment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.comment = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RecordPlanCompletionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RecordPlanCompletionRequestBuilder();
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


