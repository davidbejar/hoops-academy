//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/player_brief.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_batch_response.g.dart';

/// PlayerBatchResponse
///
/// Properties:
/// * [players]
@BuiltValue()
abstract class PlayerBatchResponse
    implements Built<PlayerBatchResponse, PlayerBatchResponseBuilder> {
  @BuiltValueField(wireName: r'players')
  BuiltList<PlayerBrief> get players;

  PlayerBatchResponse._();

  factory PlayerBatchResponse([void updates(PlayerBatchResponseBuilder b)]) =
      _$PlayerBatchResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerBatchResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerBatchResponse> get serializer =>
      _$PlayerBatchResponseSerializer();
}

class _$PlayerBatchResponseSerializer
    implements PrimitiveSerializer<PlayerBatchResponse> {
  @override
  final Iterable<Type> types = const [
    PlayerBatchResponse,
    _$PlayerBatchResponse
  ];

  @override
  final String wireName = r'PlayerBatchResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerBatchResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'players';
    yield serializers.serialize(
      object.players,
      specifiedType: const FullType(BuiltList, [FullType(PlayerBrief)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerBatchResponse object, {
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
    required PlayerBatchResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'players':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlayerBrief)]),
          ) as BuiltList<PlayerBrief>;
          result.players.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerBatchResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerBatchResponseBuilder();
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
