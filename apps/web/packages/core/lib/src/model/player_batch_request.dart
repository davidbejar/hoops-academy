//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_batch_request.g.dart';

/// PlayerBatchRequest
///
/// Properties:
/// * [playerIds]
@BuiltValue()
abstract class PlayerBatchRequest
    implements Built<PlayerBatchRequest, PlayerBatchRequestBuilder> {
  @BuiltValueField(wireName: r'playerIds')
  BuiltSet<String> get playerIds;

  PlayerBatchRequest._();

  factory PlayerBatchRequest([void updates(PlayerBatchRequestBuilder b)]) =
      _$PlayerBatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerBatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerBatchRequest> get serializer =>
      _$PlayerBatchRequestSerializer();
}

class _$PlayerBatchRequestSerializer
    implements PrimitiveSerializer<PlayerBatchRequest> {
  @override
  final Iterable<Type> types = const [PlayerBatchRequest, _$PlayerBatchRequest];

  @override
  final String wireName = r'PlayerBatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerBatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerIds';
    yield serializers.serialize(
      object.playerIds,
      specifiedType: const FullType(BuiltSet, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerBatchRequest object, {
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
    required PlayerBatchRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(String)]),
          ) as BuiltSet<String>;
          result.playerIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerBatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerBatchRequestBuilder();
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
