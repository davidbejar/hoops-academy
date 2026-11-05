//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/rebound_payload.dart';
import 'package:hoops_game_api/src/model/match_event_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'rebound_event.g.dart';

/// ReboundEvent
///
/// Properties:
/// * [id] - Client-generated UUIDv7; the idempotency key.
/// * [deviceId] - Stable id of the scoring device (installation).
/// * [clientSeq] - Per-device monotonically increasing sequence; unique per (match, deviceId).
/// * [type]
/// * [period] - 1-based period; values above the match's periodCount are overtimes.
/// * [clockSecondsRemaining] - Game clock at the event, seconds remaining in the period.
/// * [recordedAtClient] - Device wall clock (UTC) when the event was entered.
/// * [playerId] - Player the event is attributed to (must be on the match roster for the projection).
/// * [payload]
@BuiltValue()
abstract class ReboundEvent implements Built<ReboundEvent, ReboundEventBuilder> {
  /// Client-generated UUIDv7; the idempotency key.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Stable id of the scoring device (installation).
  @BuiltValueField(wireName: r'deviceId')
  String get deviceId;

  /// Per-device monotonically increasing sequence; unique per (match, deviceId).
  @BuiltValueField(wireName: r'clientSeq')
  int get clientSeq;

  @BuiltValueField(wireName: r'type')
  MatchEventType get type;
  // enum typeEnum {  PERIOD_START,  PERIOD_END,  SUB_IN,  SUB_OUT,  SHOT,  ASSIST,  REBOUND,  TURNOVER,  STEAL,  BLOCK,  FOUL,  OPPONENT_SCORE,  TIMEOUT,  VOID,  NOTE,  };

  /// 1-based period; values above the match's periodCount are overtimes.
  @BuiltValueField(wireName: r'period')
  int get period;

  /// Game clock at the event, seconds remaining in the period.
  @BuiltValueField(wireName: r'clockSecondsRemaining')
  int get clockSecondsRemaining;

  /// Device wall clock (UTC) when the event was entered.
  @BuiltValueField(wireName: r'recordedAtClient')
  DateTime get recordedAtClient;

  /// Player the event is attributed to (must be on the match roster for the projection).
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'payload')
  ReboundPayload get payload;

  ReboundEvent._();

  factory ReboundEvent([void updates(ReboundEventBuilder b)]) = _$ReboundEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReboundEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReboundEvent> get serializer => _$ReboundEventSerializer();
}

class _$ReboundEventSerializer implements PrimitiveSerializer<ReboundEvent> {
  @override
  final Iterable<Type> types = const [ReboundEvent, _$ReboundEvent];

  @override
  final String wireName = r'ReboundEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReboundEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'deviceId';
    yield serializers.serialize(
      object.deviceId,
      specifiedType: const FullType(String),
    );
    yield r'clientSeq';
    yield serializers.serialize(
      object.clientSeq,
      specifiedType: const FullType(int),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(MatchEventType),
    );
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(int),
    );
    yield r'clockSecondsRemaining';
    yield serializers.serialize(
      object.clockSecondsRemaining,
      specifiedType: const FullType(int),
    );
    yield r'recordedAtClient';
    yield serializers.serialize(
      object.recordedAtClient,
      specifiedType: const FullType(DateTime),
    );
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(ReboundPayload),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReboundEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReboundEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'deviceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deviceId = valueDes;
          break;
        case r'clientSeq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.clientSeq = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchEventType),
          ) as MatchEventType;
          result.type = valueDes;
          break;
        case r'period':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.period = valueDes;
          break;
        case r'clockSecondsRemaining':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.clockSecondsRemaining = valueDes;
          break;
        case r'recordedAtClient':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.recordedAtClient = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReboundPayload),
          ) as ReboundPayload;
          result.payload.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReboundEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReboundEventBuilder();
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
