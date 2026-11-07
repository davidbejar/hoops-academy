//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'approval_decision_request.g.dart';

/// ApprovalDecisionRequest
///
/// Properties:
/// * [note]
@BuiltValue()
abstract class ApprovalDecisionRequest
    implements Built<ApprovalDecisionRequest, ApprovalDecisionRequestBuilder> {
  @BuiltValueField(wireName: r'note')
  String? get note;

  ApprovalDecisionRequest._();

  factory ApprovalDecisionRequest(
          [void updates(ApprovalDecisionRequestBuilder b)]) =
      _$ApprovalDecisionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ApprovalDecisionRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ApprovalDecisionRequest> get serializer =>
      _$ApprovalDecisionRequestSerializer();
}

class _$ApprovalDecisionRequestSerializer
    implements PrimitiveSerializer<ApprovalDecisionRequest> {
  @override
  final Iterable<Type> types = const [
    ApprovalDecisionRequest,
    _$ApprovalDecisionRequest
  ];

  @override
  final String wireName = r'ApprovalDecisionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ApprovalDecisionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ApprovalDecisionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ApprovalDecisionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ApprovalDecisionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ApprovalDecisionRequestBuilder();
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
