//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'taken_jersey_number.g.dart';

/// A number held by an open assignment of the team.
///
/// Properties:
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [player] 
@BuiltValue()
abstract class TakenJerseyNumber implements Built<TakenJerseyNumber, TakenJerseyNumberBuilder> {
  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String get jerseyNumber;

  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  TakenJerseyNumber._();

  factory TakenJerseyNumber([void updates(TakenJerseyNumberBuilder b)]) = _$TakenJerseyNumber;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TakenJerseyNumberBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TakenJerseyNumber> get serializer => _$TakenJerseyNumberSerializer();
}

class _$TakenJerseyNumberSerializer implements PrimitiveSerializer<TakenJerseyNumber> {
  @override
  final Iterable<Type> types = const [TakenJerseyNumber, _$TakenJerseyNumber];

  @override
  final String wireName = r'TakenJerseyNumber';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TakenJerseyNumber object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'jerseyNumber';
    yield serializers.serialize(
      object.jerseyNumber,
      specifiedType: const FullType(String),
    );
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(PlayerRef),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TakenJerseyNumber object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TakenJerseyNumberBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jerseyNumber = valueDes;
          break;
        case r'player':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerRef),
          ) as PlayerRef;
          result.player.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TakenJerseyNumber deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TakenJerseyNumberBuilder();
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


