//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/opponent_score_payload.dart';
import 'package:hoops_game_api/src/model/match_event_base.dart';
import 'package:hoops_game_api/src/model/match_event_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'opponent_score_event.g.dart';

/// Points scored by the opponent (staff only).
///
/// Properties:
/// * [id] - Client-generated UUIDv7; the idempotency key.
/// * [deviceId] - Stable id of the scoring device (installation).
/// * [clientSeq] - Per-device monotonically increasing sequence; unique per (match, deviceId).
/// * [type] 
/// * [period] - 1-based period; values above the match's periodCount are overtimes.
/// * [clockSecondsRemaining] - Game clock at the event, seconds remaining in the period.
/// * [recordedAtClient] - Device wall clock (UTC) when the event was entered.
/// * [payload] 
@BuiltValue()
abstract class OpponentScoreEvent implements MatchEventBase, Built<OpponentScoreEvent, OpponentScoreEventBuilder> {
  @BuiltValueField(wireName: r'payload')
  OpponentScorePayload get payload;

  OpponentScoreEvent._();

  factory OpponentScoreEvent([void updates(OpponentScoreEventBuilder b)]) = _$OpponentScoreEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OpponentScoreEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OpponentScoreEvent> get serializer => _$OpponentScoreEventSerializer();
}

class _$OpponentScoreEventSerializer implements PrimitiveSerializer<OpponentScoreEvent> {
  @override
  final Iterable<Type> types = const [OpponentScoreEvent, _$OpponentScoreEvent];

  @override
  final String wireName = r'OpponentScoreEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OpponentScoreEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(int),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(OpponentScorePayload),
    );
    yield r'clientSeq';
    yield serializers.serialize(
      object.clientSeq,
      specifiedType: const FullType(int),
    );
    yield r'recordedAtClient';
    yield serializers.serialize(
      object.recordedAtClient,
      specifiedType: const FullType(DateTime),
    );
    yield r'clockSecondsRemaining';
    yield serializers.serialize(
      object.clockSecondsRemaining,
      specifiedType: const FullType(int),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(MatchEventType),
    );
    yield r'deviceId';
    yield serializers.serialize(
      object.deviceId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OpponentScoreEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OpponentScoreEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'period':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.period = valueDes;
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OpponentScorePayload),
          ) as OpponentScorePayload;
          result.payload.replace(valueDes);
          break;
        case r'clientSeq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.clientSeq = valueDes;
          break;
        case r'recordedAtClient':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.recordedAtClient = valueDes;
          break;
        case r'clockSecondsRemaining':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.clockSecondsRemaining = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchEventType),
          ) as MatchEventType;
          result.type = valueDes;
          break;
        case r'deviceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OpponentScoreEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OpponentScoreEventBuilder();
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


