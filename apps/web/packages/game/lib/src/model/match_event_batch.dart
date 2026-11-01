//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_event.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_batch.g.dart';

/// MatchEventBatch
///
/// Properties:
/// * [events] 
@BuiltValue()
abstract class MatchEventBatch implements Built<MatchEventBatch, MatchEventBatchBuilder> {
  @BuiltValueField(wireName: r'events')
  BuiltList<MatchEvent> get events;

  MatchEventBatch._();

  factory MatchEventBatch([void updates(MatchEventBatchBuilder b)]) = _$MatchEventBatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchEventBatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchEventBatch> get serializer => _$MatchEventBatchSerializer();
}

class _$MatchEventBatchSerializer implements PrimitiveSerializer<MatchEventBatch> {
  @override
  final Iterable<Type> types = const [MatchEventBatch, _$MatchEventBatch];

  @override
  final String wireName = r'MatchEventBatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchEventBatch object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'events';
    yield serializers.serialize(
      object.events,
      specifiedType: const FullType(BuiltList, [FullType(MatchEvent)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchEventBatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchEventBatchBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(MatchEvent)]),
          ) as BuiltList<MatchEvent>;
          result.events.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchEventBatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchEventBatchBuilder();
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


