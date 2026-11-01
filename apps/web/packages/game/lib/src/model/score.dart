//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'score.g.dart';

/// Score
///
/// Properties:
/// * [team] 
/// * [opponent] 
@BuiltValue()
abstract class Score implements Built<Score, ScoreBuilder> {
  @BuiltValueField(wireName: r'team')
  int get team;

  @BuiltValueField(wireName: r'opponent')
  int get opponent;

  Score._();

  factory Score([void updates(ScoreBuilder b)]) = _$Score;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScoreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Score> get serializer => _$ScoreSerializer();
}

class _$ScoreSerializer implements PrimitiveSerializer<Score> {
  @override
  final Iterable<Type> types = const [Score, _$Score];

  @override
  final String wireName = r'Score';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Score object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'team';
    yield serializers.serialize(
      object.team,
      specifiedType: const FullType(int),
    );
    yield r'opponent';
    yield serializers.serialize(
      object.opponent,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Score object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScoreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'team':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.team = valueDes;
          break;
        case r'opponent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.opponent = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Score deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScoreBuilder();
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


