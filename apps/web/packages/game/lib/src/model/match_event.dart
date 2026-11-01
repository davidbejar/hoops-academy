//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/note_event.dart';
import 'package:hoops_game_api/src/model/sub_in_event.dart';
import 'package:hoops_game_api/src/model/void_event.dart';
import 'package:hoops_game_api/src/model/assist_event.dart';
import 'package:hoops_game_api/src/model/shot_event.dart';
import 'package:hoops_game_api/src/model/sub_out_event.dart';
import 'package:hoops_game_api/src/model/foul_event.dart';
import 'package:hoops_game_api/src/model/note_payload.dart';
import 'package:hoops_game_api/src/model/turnover_event.dart';
import 'package:hoops_game_api/src/model/block_event.dart';
import 'package:hoops_game_api/src/model/period_end_event.dart';
import 'package:hoops_game_api/src/model/rebound_event.dart';
import 'package:hoops_game_api/src/model/timeout_event.dart';
import 'package:hoops_game_api/src/model/opponent_score_event.dart';
import 'package:hoops_game_api/src/model/steal_event.dart';
import 'package:hoops_game_api/src/model/match_event_type.dart';
import 'package:hoops_game_api/src/model/period_start_event.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'match_event.g.dart';

/// A match event, polymorphic on `type`.
///
/// Properties:
/// * [id] - Client-generated UUIDv7; the idempotency key.
/// * [deviceId] - Stable id of the scoring device (installation).
/// * [clientSeq] - Per-device monotonically increasing sequence; unique per (match, deviceId).
/// * [type] 
/// * [period] - 1-based period; values above the match's periodCount are overtimes.
/// * [clockSecondsRemaining] - Game clock at the event, seconds remaining in the period.
/// * [recordedAtClient] - Device wall clock (UTC) when the event was entered.
/// * [playerId] 
/// * [payload] 
@BuiltValue()
abstract class MatchEvent implements Built<MatchEvent, MatchEventBuilder> {
  /// One Of [AssistEvent], [BlockEvent], [FoulEvent], [NoteEvent], [OpponentScoreEvent], [PeriodEndEvent], [PeriodStartEvent], [ReboundEvent], [ShotEvent], [StealEvent], [SubInEvent], [SubOutEvent], [TimeoutEvent], [TurnoverEvent], [VoidEvent]
  OneOf get oneOf;

  static const String discriminatorFieldName = r'type';

  static const Map<String, Type> discriminatorMapping = {
    r'ASSIST': AssistEvent,
    r'BLOCK': BlockEvent,
    r'FOUL': FoulEvent,
    r'NOTE': NoteEvent,
    r'OPPONENT_SCORE': OpponentScoreEvent,
    r'PERIOD_END': PeriodEndEvent,
    r'PERIOD_START': PeriodStartEvent,
    r'REBOUND': ReboundEvent,
    r'SHOT': ShotEvent,
    r'STEAL': StealEvent,
    r'SUB_IN': SubInEvent,
    r'SUB_OUT': SubOutEvent,
    r'TIMEOUT': TimeoutEvent,
    r'TURNOVER': TurnoverEvent,
    r'VOID': VoidEvent,
  };

  MatchEvent._();

  factory MatchEvent([void updates(MatchEventBuilder b)]) = _$MatchEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchEvent> get serializer => _$MatchEventSerializer();
}

extension MatchEventDiscriminatorExt on MatchEvent {
    String? get discriminatorValue {
        if (this is AssistEvent) {
            return r'ASSIST';
        }
        if (this is BlockEvent) {
            return r'BLOCK';
        }
        if (this is FoulEvent) {
            return r'FOUL';
        }
        if (this is NoteEvent) {
            return r'NOTE';
        }
        if (this is OpponentScoreEvent) {
            return r'OPPONENT_SCORE';
        }
        if (this is PeriodEndEvent) {
            return r'PERIOD_END';
        }
        if (this is PeriodStartEvent) {
            return r'PERIOD_START';
        }
        if (this is ReboundEvent) {
            return r'REBOUND';
        }
        if (this is ShotEvent) {
            return r'SHOT';
        }
        if (this is StealEvent) {
            return r'STEAL';
        }
        if (this is SubInEvent) {
            return r'SUB_IN';
        }
        if (this is SubOutEvent) {
            return r'SUB_OUT';
        }
        if (this is TimeoutEvent) {
            return r'TIMEOUT';
        }
        if (this is TurnoverEvent) {
            return r'TURNOVER';
        }
        if (this is VoidEvent) {
            return r'VOID';
        }
        return null;
    }
}
extension MatchEventBuilderDiscriminatorExt on MatchEventBuilder {
    String? get discriminatorValue {
        if (this is AssistEventBuilder) {
            return r'ASSIST';
        }
        if (this is BlockEventBuilder) {
            return r'BLOCK';
        }
        if (this is FoulEventBuilder) {
            return r'FOUL';
        }
        if (this is NoteEventBuilder) {
            return r'NOTE';
        }
        if (this is OpponentScoreEventBuilder) {
            return r'OPPONENT_SCORE';
        }
        if (this is PeriodEndEventBuilder) {
            return r'PERIOD_END';
        }
        if (this is PeriodStartEventBuilder) {
            return r'PERIOD_START';
        }
        if (this is ReboundEventBuilder) {
            return r'REBOUND';
        }
        if (this is ShotEventBuilder) {
            return r'SHOT';
        }
        if (this is StealEventBuilder) {
            return r'STEAL';
        }
        if (this is SubInEventBuilder) {
            return r'SUB_IN';
        }
        if (this is SubOutEventBuilder) {
            return r'SUB_OUT';
        }
        if (this is TimeoutEventBuilder) {
            return r'TIMEOUT';
        }
        if (this is TurnoverEventBuilder) {
            return r'TURNOVER';
        }
        if (this is VoidEventBuilder) {
            return r'VOID';
        }
        return null;
    }
}

class _$MatchEventSerializer implements PrimitiveSerializer<MatchEvent> {
  @override
  final Iterable<Type> types = const [MatchEvent, _$MatchEvent];

  @override
  final String wireName = r'MatchEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(oneOf.value, specifiedType: FullType(oneOf.valueType))!;
  }

  @override
  MatchEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchEventBuilder();
    Object? oneOfDataSrc;
    final serializedList = (serialized as Iterable<Object?>).toList();
    final discIndex = serializedList.indexOf(MatchEvent.discriminatorFieldName) + 1;
    final discValue = serializers.deserialize(serializedList[discIndex], specifiedType: FullType(String)) as String;
    oneOfDataSrc = serialized;
    final oneOfTypes = [AssistEvent, BlockEvent, FoulEvent, NoteEvent, OpponentScoreEvent, PeriodEndEvent, PeriodStartEvent, ReboundEvent, ShotEvent, StealEvent, SubInEvent, SubOutEvent, TimeoutEvent, TurnoverEvent, VoidEvent, ];
    Object oneOfResult;
    Type oneOfType;
    switch (discValue) {
      case r'ASSIST':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(AssistEvent),
        ) as AssistEvent;
        oneOfType = AssistEvent;
        break;
      case r'BLOCK':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(BlockEvent),
        ) as BlockEvent;
        oneOfType = BlockEvent;
        break;
      case r'FOUL':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(FoulEvent),
        ) as FoulEvent;
        oneOfType = FoulEvent;
        break;
      case r'NOTE':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(NoteEvent),
        ) as NoteEvent;
        oneOfType = NoteEvent;
        break;
      case r'OPPONENT_SCORE':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(OpponentScoreEvent),
        ) as OpponentScoreEvent;
        oneOfType = OpponentScoreEvent;
        break;
      case r'PERIOD_END':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(PeriodEndEvent),
        ) as PeriodEndEvent;
        oneOfType = PeriodEndEvent;
        break;
      case r'PERIOD_START':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(PeriodStartEvent),
        ) as PeriodStartEvent;
        oneOfType = PeriodStartEvent;
        break;
      case r'REBOUND':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ReboundEvent),
        ) as ReboundEvent;
        oneOfType = ReboundEvent;
        break;
      case r'SHOT':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(ShotEvent),
        ) as ShotEvent;
        oneOfType = ShotEvent;
        break;
      case r'STEAL':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(StealEvent),
        ) as StealEvent;
        oneOfType = StealEvent;
        break;
      case r'SUB_IN':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(SubInEvent),
        ) as SubInEvent;
        oneOfType = SubInEvent;
        break;
      case r'SUB_OUT':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(SubOutEvent),
        ) as SubOutEvent;
        oneOfType = SubOutEvent;
        break;
      case r'TIMEOUT':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(TimeoutEvent),
        ) as TimeoutEvent;
        oneOfType = TimeoutEvent;
        break;
      case r'TURNOVER':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(TurnoverEvent),
        ) as TurnoverEvent;
        oneOfType = TurnoverEvent;
        break;
      case r'VOID':
        oneOfResult = serializers.deserialize(
          oneOfDataSrc,
          specifiedType: FullType(VoidEvent),
        ) as VoidEvent;
        oneOfType = VoidEvent;
        break;
      default:
        throw UnsupportedError("Couldn't deserialize oneOf for the discriminator value: ${discValue}");
    }
    result.oneOf = OneOfDynamic(typeIndex: oneOfTypes.indexOf(oneOfType), types: oneOfTypes, value: oneOfResult);
    return result.build();
  }
}


