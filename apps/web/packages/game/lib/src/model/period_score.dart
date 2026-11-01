//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'period_score.g.dart';

/// PeriodScore
///
/// Properties:
/// * [period] 
/// * [team] 
/// * [opponent] 
@BuiltValue()
abstract class PeriodScore implements Built<PeriodScore, PeriodScoreBuilder> {
  @BuiltValueField(wireName: r'period')
  int get period;

  @BuiltValueField(wireName: r'team')
  int get team;

  @BuiltValueField(wireName: r'opponent')
  int get opponent;

  PeriodScore._();

  factory PeriodScore([void updates(PeriodScoreBuilder b)]) = _$PeriodScore;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PeriodScoreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PeriodScore> get serializer => _$PeriodScoreSerializer();
}

class _$PeriodScoreSerializer implements PrimitiveSerializer<PeriodScore> {
  @override
  final Iterable<Type> types = const [PeriodScore, _$PeriodScore];

  @override
  final String wireName = r'PeriodScore';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PeriodScore object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(int),
    );
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
    PeriodScore object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PeriodScoreBuilder result,
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
  PeriodScore deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PeriodScoreBuilder();
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


