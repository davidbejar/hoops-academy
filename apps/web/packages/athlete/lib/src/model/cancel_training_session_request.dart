//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cancel_training_session_request.g.dart';

/// CancelTrainingSessionRequest
///
/// Properties:
/// * [reason] 
@BuiltValue()
abstract class CancelTrainingSessionRequest implements Built<CancelTrainingSessionRequest, CancelTrainingSessionRequestBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  CancelTrainingSessionRequest._();

  factory CancelTrainingSessionRequest([void updates(CancelTrainingSessionRequestBuilder b)]) = _$CancelTrainingSessionRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CancelTrainingSessionRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CancelTrainingSessionRequest> get serializer => _$CancelTrainingSessionRequestSerializer();
}

class _$CancelTrainingSessionRequestSerializer implements PrimitiveSerializer<CancelTrainingSessionRequest> {
  @override
  final Iterable<Type> types = const [CancelTrainingSessionRequest, _$CancelTrainingSessionRequest];

  @override
  final String wireName = r'CancelTrainingSessionRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CancelTrainingSessionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CancelTrainingSessionRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CancelTrainingSessionRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CancelTrainingSessionRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CancelTrainingSessionRequestBuilder();
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


