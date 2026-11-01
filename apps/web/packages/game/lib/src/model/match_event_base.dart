//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_event_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_base.g.dart';

/// Fields common to every match event.
///
/// Properties:
/// * [id] - Client-generated UUIDv7; the idempotency key.
/// * [deviceId] - Stable id of the scoring device (installation).
/// * [clientSeq] - Per-device monotonically increasing sequence; unique per (match, deviceId).
/// * [type] 
/// * [period] - 1-based period; values above the match's periodCount are overtimes.
/// * [clockSecondsRemaining] - Game clock at the event, seconds remaining in the period.
/// * [recordedAtClient] - Device wall clock (UTC) when the event was entered.
@BuiltValue(instantiable: false)
abstract class MatchEventBase  {
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

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchEventBase> get serializer => _$MatchEventBaseSerializer();
}

class _$MatchEventBaseSerializer implements PrimitiveSerializer<MatchEventBase> {
  @override
  final Iterable<Type> types = const [MatchEventBase];

  @override
  final String wireName = r'MatchEventBase';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchEventBase object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchEventBase object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  MatchEventBase deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($MatchEventBase)) as $MatchEventBase;
  }
}


/// a concrete implementation of [MatchEventBase], since [MatchEventBase] is not instantiable
@BuiltValue(instantiable: true)
abstract class $MatchEventBase implements MatchEventBase, Built<$MatchEventBase, $MatchEventBaseBuilder> {
  $MatchEventBase._();

  factory $MatchEventBase([void Function($MatchEventBaseBuilder)? updates]) = _$$MatchEventBase;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($MatchEventBaseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$MatchEventBase> get serializer => _$$MatchEventBaseSerializer();
}

class _$$MatchEventBaseSerializer implements PrimitiveSerializer<$MatchEventBase> {
  @override
  final Iterable<Type> types = const [$MatchEventBase, _$$MatchEventBase];

  @override
  final String wireName = r'$MatchEventBase';

  @override
  Object serialize(
    Serializers serializers,
    $MatchEventBase object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(MatchEventBase))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchEventBaseBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  $MatchEventBase deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $MatchEventBaseBuilder();
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

