//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_event_result.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_batch_result.g.dart';

/// MatchEventBatchResult
///
/// Properties:
/// * [results] 
/// * [lastServerSeq] 
@BuiltValue()
abstract class MatchEventBatchResult implements Built<MatchEventBatchResult, MatchEventBatchResultBuilder> {
  @BuiltValueField(wireName: r'results')
  BuiltList<MatchEventResult> get results;

  @BuiltValueField(wireName: r'lastServerSeq')
  int get lastServerSeq;

  MatchEventBatchResult._();

  factory MatchEventBatchResult([void updates(MatchEventBatchResultBuilder b)]) = _$MatchEventBatchResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchEventBatchResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchEventBatchResult> get serializer => _$MatchEventBatchResultSerializer();
}

class _$MatchEventBatchResultSerializer implements PrimitiveSerializer<MatchEventBatchResult> {
  @override
  final Iterable<Type> types = const [MatchEventBatchResult, _$MatchEventBatchResult];

  @override
  final String wireName = r'MatchEventBatchResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchEventBatchResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'results';
    yield serializers.serialize(
      object.results,
      specifiedType: const FullType(BuiltList, [FullType(MatchEventResult)]),
    );
    yield r'lastServerSeq';
    yield serializers.serialize(
      object.lastServerSeq,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchEventBatchResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchEventBatchResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'results':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(MatchEventResult)]),
          ) as BuiltList<MatchEventResult>;
          result.results.replace(valueDes);
          break;
        case r'lastServerSeq':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.lastServerSeq = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchEventBatchResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchEventBatchResultBuilder();
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


