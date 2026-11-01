//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'opponent_score_payload.g.dart';

/// OpponentScorePayload
///
/// Properties:
/// * [points] 
@BuiltValue()
abstract class OpponentScorePayload implements Built<OpponentScorePayload, OpponentScorePayloadBuilder> {
  @BuiltValueField(wireName: r'points')
  OpponentScorePayloadPointsEnum get points;
  // enum pointsEnum {  1,  2,  3,  };

  OpponentScorePayload._();

  factory OpponentScorePayload([void updates(OpponentScorePayloadBuilder b)]) = _$OpponentScorePayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OpponentScorePayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OpponentScorePayload> get serializer => _$OpponentScorePayloadSerializer();
}

class _$OpponentScorePayloadSerializer implements PrimitiveSerializer<OpponentScorePayload> {
  @override
  final Iterable<Type> types = const [OpponentScorePayload, _$OpponentScorePayload];

  @override
  final String wireName = r'OpponentScorePayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OpponentScorePayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'points';
    yield serializers.serialize(
      object.points,
      specifiedType: const FullType(OpponentScorePayloadPointsEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OpponentScorePayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OpponentScorePayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'points':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OpponentScorePayloadPointsEnum),
          ) as OpponentScorePayloadPointsEnum;
          result.points = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OpponentScorePayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OpponentScorePayloadBuilder();
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


class OpponentScorePayloadPointsEnum extends EnumClass {

  @BuiltValueEnumConst(wireNumber: 1)
  static const OpponentScorePayloadPointsEnum number1 = _$opponentScorePayloadPointsEnum_number1;
  @BuiltValueEnumConst(wireNumber: 2)
  static const OpponentScorePayloadPointsEnum number2 = _$opponentScorePayloadPointsEnum_number2;
  @BuiltValueEnumConst(wireNumber: 3)
  static const OpponentScorePayloadPointsEnum number3 = _$opponentScorePayloadPointsEnum_number3;
  @BuiltValueEnumConst(wireNumber: 11184809, fallback: true)
  static const OpponentScorePayloadPointsEnum unknownDefaultOpenApi = _$opponentScorePayloadPointsEnum_unknownDefaultOpenApi;

  static Serializer<OpponentScorePayloadPointsEnum> get serializer => _$opponentScorePayloadPointsEnumSerializer;

  const OpponentScorePayloadPointsEnum._(String name): super(name);

  static BuiltSet<OpponentScorePayloadPointsEnum> get values => _$opponentScorePayloadPointsEnumValues;
  static OpponentScorePayloadPointsEnum valueOf(String name) => _$opponentScorePayloadPointsEnumValueOf(name);
}

