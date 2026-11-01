//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cancel_match_request.g.dart';

/// CancelMatchRequest
///
/// Properties:
/// * [reason] 
@BuiltValue()
abstract class CancelMatchRequest implements Built<CancelMatchRequest, CancelMatchRequestBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  CancelMatchRequest._();

  factory CancelMatchRequest([void updates(CancelMatchRequestBuilder b)]) = _$CancelMatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CancelMatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CancelMatchRequest> get serializer => _$CancelMatchRequestSerializer();
}

class _$CancelMatchRequestSerializer implements PrimitiveSerializer<CancelMatchRequest> {
  @override
  final Iterable<Type> types = const [CancelMatchRequest, _$CancelMatchRequest];

  @override
  final String wireName = r'CancelMatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CancelMatchRequest object, {
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
    CancelMatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CancelMatchRequestBuilder result,
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
  CancelMatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CancelMatchRequestBuilder();
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


