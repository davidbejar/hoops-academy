//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_event_rejection_reason.dart';
import 'package:hoops_game_api/src/model/match_event_result_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_result.g.dart';

/// MatchEventResult
///
/// Properties:
/// * [eventId] 
/// * [status] 
/// * [serverSeq] - Set for ACCEPTED and DUPLICATE.
/// * [reason] - Set for REJECTED.
/// * [message] - Human-readable detail for REJECTED (e.g. the failing schema path).
@BuiltValue()
abstract class MatchEventResult implements Built<MatchEventResult, MatchEventResultBuilder> {
  @BuiltValueField(wireName: r'eventId')
  String get eventId;

  @BuiltValueField(wireName: r'status')
  MatchEventResultStatus get status;
  // enum statusEnum {  ACCEPTED,  DUPLICATE,  REJECTED,  };

  /// Set for ACCEPTED and DUPLICATE.
  @BuiltValueField(wireName: r'serverSeq')
  int? get serverSeq;

  /// Set for REJECTED.
  @BuiltValueField(wireName: r'reason')
  MatchEventRejectionReason? get reason;
  // enum reasonEnum {  SCHEMA_INVALID,  NOT_AUTHORIZED,  MATCH_CANCELLED,  CLIENT_SEQ_CONFLICT,  EVENT_ID_REUSED,  MATCH_NOT_STARTED,  };

  /// Human-readable detail for REJECTED (e.g. the failing schema path).
  @BuiltValueField(wireName: r'message')
  String? get message;

  MatchEventResult._();

  factory MatchEventResult([void updates(MatchEventResultBuilder b)]) = _$MatchEventResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchEventResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchEventResult> get serializer => _$MatchEventResultSerializer();
}

class _$MatchEventResultSerializer implements PrimitiveSerializer<MatchEventResult> {
  @override
  final Iterable<Type> types = const [MatchEventResult, _$MatchEventResult];

  @override
  final String wireName = r'MatchEventResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchEventResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'eventId';
    yield serializers.serialize(
      object.eventId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MatchEventResultStatus),
    );
    if (object.serverSeq != null) {
      yield r'serverSeq';
      yield serializers.serialize(
        object.serverSeq,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(MatchEventRejectionReason),
      );
    }
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchEventResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchEventResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'eventId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.eventId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchEventResultStatus),
          ) as MatchEventResultStatus;
          result.status = valueDes;
          break;
        case r'serverSeq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.serverSeq = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(MatchEventRejectionReason),
          ) as MatchEventRejectionReason?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchEventResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchEventResultBuilder();
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


