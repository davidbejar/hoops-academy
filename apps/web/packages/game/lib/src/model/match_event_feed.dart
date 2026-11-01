//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_game_api/src/model/stored_match_event.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_feed.g.dart';

/// MatchEventFeed
///
/// Properties:
/// * [events] 
/// * [lastServerSeq] - Highest stored `serverSeq` of the match (cursor for the next call when hasMore = false).
/// * [hasMore] - More events exist after the last returned one.
@BuiltValue()
abstract class MatchEventFeed implements Built<MatchEventFeed, MatchEventFeedBuilder> {
  @BuiltValueField(wireName: r'events')
  BuiltList<StoredMatchEvent> get events;

  /// Highest stored `serverSeq` of the match (cursor for the next call when hasMore = false).
  @BuiltValueField(wireName: r'lastServerSeq')
  int get lastServerSeq;

  /// More events exist after the last returned one.
  @BuiltValueField(wireName: r'hasMore')
  bool get hasMore;

  MatchEventFeed._();

  factory MatchEventFeed([void updates(MatchEventFeedBuilder b)]) = _$MatchEventFeed;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchEventFeedBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchEventFeed> get serializer => _$MatchEventFeedSerializer();
}

class _$MatchEventFeedSerializer implements PrimitiveSerializer<MatchEventFeed> {
  @override
  final Iterable<Type> types = const [MatchEventFeed, _$MatchEventFeed];

  @override
  final String wireName = r'MatchEventFeed';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchEventFeed object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'events';
    yield serializers.serialize(
      object.events,
      specifiedType: const FullType(BuiltList, [FullType(StoredMatchEvent)]),
    );
    yield r'lastServerSeq';
    yield serializers.serialize(
      object.lastServerSeq,
      specifiedType: const FullType(int),
    );
    yield r'hasMore';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchEventFeed object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchEventFeedBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(StoredMatchEvent)]),
          ) as BuiltList<StoredMatchEvent>;
          result.events.replace(valueDes);
          break;
        case r'lastServerSeq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.lastServerSeq = valueDes;
          break;
        case r'hasMore':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasMore = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchEventFeed deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchEventFeedBuilder();
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


