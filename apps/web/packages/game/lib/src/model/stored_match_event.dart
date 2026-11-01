//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_event.dart';
import 'package:hoops_game_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'stored_match_event.g.dart';

/// A match event as stored by the server.
///
/// Properties:
/// * [serverSeq] 
/// * [event] 
/// * [recordedBy] 
/// * [receivedAt] 
/// * [voidedByEventId] - Set when a later VOID event targets this event.
@BuiltValue()
abstract class StoredMatchEvent implements Built<StoredMatchEvent, StoredMatchEventBuilder> {
  @BuiltValueField(wireName: r'serverSeq')
  int get serverSeq;

  @BuiltValueField(wireName: r'event')
  MatchEvent get event;

  @BuiltValueField(wireName: r'recordedBy')
  PersonRef get recordedBy;

  @BuiltValueField(wireName: r'receivedAt')
  DateTime get receivedAt;

  /// Set when a later VOID event targets this event.
  @BuiltValueField(wireName: r'voidedByEventId')
  String? get voidedByEventId;

  StoredMatchEvent._();

  factory StoredMatchEvent([void updates(StoredMatchEventBuilder b)]) = _$StoredMatchEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StoredMatchEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StoredMatchEvent> get serializer => _$StoredMatchEventSerializer();
}

class _$StoredMatchEventSerializer implements PrimitiveSerializer<StoredMatchEvent> {
  @override
  final Iterable<Type> types = const [StoredMatchEvent, _$StoredMatchEvent];

  @override
  final String wireName = r'StoredMatchEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StoredMatchEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'serverSeq';
    yield serializers.serialize(
      object.serverSeq,
      specifiedType: const FullType(int),
    );
    yield r'event';
    yield serializers.serialize(
      object.event,
      specifiedType: const FullType(MatchEvent),
    );
    yield r'recordedBy';
    yield serializers.serialize(
      object.recordedBy,
      specifiedType: const FullType(PersonRef),
    );
    yield r'receivedAt';
    yield serializers.serialize(
      object.receivedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.voidedByEventId != null) {
      yield r'voidedByEventId';
      yield serializers.serialize(
        object.voidedByEventId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    StoredMatchEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required StoredMatchEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'serverSeq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.serverSeq = valueDes;
          break;
        case r'event':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchEvent),
          ) as MatchEvent;
          result.event.replace(valueDes);
          break;
        case r'recordedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.recordedBy.replace(valueDes);
          break;
        case r'receivedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.receivedAt = valueDes;
          break;
        case r'voidedByEventId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.voidedByEventId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  StoredMatchEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StoredMatchEventBuilder();
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


