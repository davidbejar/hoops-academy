//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'withdraw_player_request.g.dart';

/// WithdrawPlayerRequest
///
/// Properties:
/// * [reason]
@BuiltValue()
abstract class WithdrawPlayerRequest
    implements Built<WithdrawPlayerRequest, WithdrawPlayerRequestBuilder> {
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  WithdrawPlayerRequest._();

  factory WithdrawPlayerRequest(
      [void updates(WithdrawPlayerRequestBuilder b)]) = _$WithdrawPlayerRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WithdrawPlayerRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WithdrawPlayerRequest> get serializer =>
      _$WithdrawPlayerRequestSerializer();
}

class _$WithdrawPlayerRequestSerializer
    implements PrimitiveSerializer<WithdrawPlayerRequest> {
  @override
  final Iterable<Type> types = const [
    WithdrawPlayerRequest,
    _$WithdrawPlayerRequest
  ];

  @override
  final String wireName = r'WithdrawPlayerRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WithdrawPlayerRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WithdrawPlayerRequest object, {
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
    required WithdrawPlayerRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  WithdrawPlayerRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WithdrawPlayerRequestBuilder();
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
