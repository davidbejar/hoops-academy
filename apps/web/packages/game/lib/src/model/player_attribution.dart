//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_attribution.g.dart';

/// PlayerAttribution
///
/// Properties:
/// * [playerId] - Player the event is attributed to (must be on the match roster for the projection).
@BuiltValue(instantiable: false)
abstract class PlayerAttribution  {
  /// Player the event is attributed to (must be on the match roster for the projection).
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerAttribution> get serializer => _$PlayerAttributionSerializer();
}

class _$PlayerAttributionSerializer implements PrimitiveSerializer<PlayerAttribution> {
  @override
  final Iterable<Type> types = const [PlayerAttribution];

  @override
  final String wireName = r'PlayerAttribution';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerAttribution object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerAttribution object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  PlayerAttribution deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($PlayerAttribution)) as $PlayerAttribution;
  }
}


/// a concrete implementation of [PlayerAttribution], since [PlayerAttribution] is not instantiable
@BuiltValue(instantiable: true)
abstract class $PlayerAttribution implements PlayerAttribution, Built<$PlayerAttribution, $PlayerAttributionBuilder> {
  $PlayerAttribution._();

  factory $PlayerAttribution([void Function($PlayerAttributionBuilder)? updates]) = _$$PlayerAttribution;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($PlayerAttributionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$PlayerAttribution> get serializer => _$$PlayerAttributionSerializer();
}

class _$$PlayerAttributionSerializer implements PrimitiveSerializer<$PlayerAttribution> {
  @override
  final Iterable<Type> types = const [$PlayerAttribution, _$$PlayerAttribution];

  @override
  final String wireName = r'$PlayerAttribution';

  @override
  Object serialize(
    Serializers serializers,
    $PlayerAttribution object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(PlayerAttribution))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerAttributionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  $PlayerAttribution deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $PlayerAttributionBuilder();
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

