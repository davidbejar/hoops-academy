//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'stat_line.g.dart';

/// Counting statistics. fg1 = free throws, fg2 = two-point field goals, fg3 = three-pointers.
///
/// Properties:
/// * [points] 
/// * [fg1Made] 
/// * [fg1Attempted] 
/// * [fg2Made] 
/// * [fg2Attempted] 
/// * [fg3Made] 
/// * [fg3Attempted] 
/// * [assists] 
/// * [offensiveRebounds] 
/// * [defensiveRebounds] 
/// * [turnovers] 
/// * [steals] 
/// * [blocks] 
/// * [personalFouls] - All fouls committed (PERSONAL + TECHNICAL + UNSPORTSMANLIKE).
/// * [technicalFouls] - TECHNICAL fouls (also counted in personalFouls).
/// * [unsportsmanlikeFouls] - UNSPORTSMANLIKE fouls (also counted in personalFouls).
/// * [secondsPlayed] - Derived from starters and period / substitution events.
@BuiltValue()
abstract class StatLine implements Built<StatLine, StatLineBuilder> {
  @BuiltValueField(wireName: r'points')
  int get points;

  @BuiltValueField(wireName: r'fg1Made')
  int get fg1Made;

  @BuiltValueField(wireName: r'fg1Attempted')
  int get fg1Attempted;

  @BuiltValueField(wireName: r'fg2Made')
  int get fg2Made;

  @BuiltValueField(wireName: r'fg2Attempted')
  int get fg2Attempted;

  @BuiltValueField(wireName: r'fg3Made')
  int get fg3Made;

  @BuiltValueField(wireName: r'fg3Attempted')
  int get fg3Attempted;

  @BuiltValueField(wireName: r'assists')
  int get assists;

  @BuiltValueField(wireName: r'offensiveRebounds')
  int get offensiveRebounds;

  @BuiltValueField(wireName: r'defensiveRebounds')
  int get defensiveRebounds;

  @BuiltValueField(wireName: r'turnovers')
  int get turnovers;

  @BuiltValueField(wireName: r'steals')
  int get steals;

  @BuiltValueField(wireName: r'blocks')
  int get blocks;

  /// All fouls committed (PERSONAL + TECHNICAL + UNSPORTSMANLIKE).
  @BuiltValueField(wireName: r'personalFouls')
  int get personalFouls;

  /// TECHNICAL fouls (also counted in personalFouls).
  @BuiltValueField(wireName: r'technicalFouls')
  int get technicalFouls;

  /// UNSPORTSMANLIKE fouls (also counted in personalFouls).
  @BuiltValueField(wireName: r'unsportsmanlikeFouls')
  int get unsportsmanlikeFouls;

  /// Derived from starters and period / substitution events.
  @BuiltValueField(wireName: r'secondsPlayed')
  int get secondsPlayed;

  StatLine._();

  factory StatLine([void updates(StatLineBuilder b)]) = _$StatLine;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StatLineBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StatLine> get serializer => _$StatLineSerializer();
}

class _$StatLineSerializer implements PrimitiveSerializer<StatLine> {
  @override
  final Iterable<Type> types = const [StatLine, _$StatLine];

  @override
  final String wireName = r'StatLine';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StatLine object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'points';
    yield serializers.serialize(
      object.points,
      specifiedType: const FullType(int),
    );
    yield r'fg1Made';
    yield serializers.serialize(
      object.fg1Made,
      specifiedType: const FullType(int),
    );
    yield r'fg1Attempted';
    yield serializers.serialize(
      object.fg1Attempted,
      specifiedType: const FullType(int),
    );
    yield r'fg2Made';
    yield serializers.serialize(
      object.fg2Made,
      specifiedType: const FullType(int),
    );
    yield r'fg2Attempted';
    yield serializers.serialize(
      object.fg2Attempted,
      specifiedType: const FullType(int),
    );
    yield r'fg3Made';
    yield serializers.serialize(
      object.fg3Made,
      specifiedType: const FullType(int),
    );
    yield r'fg3Attempted';
    yield serializers.serialize(
      object.fg3Attempted,
      specifiedType: const FullType(int),
    );
    yield r'assists';
    yield serializers.serialize(
      object.assists,
      specifiedType: const FullType(int),
    );
    yield r'offensiveRebounds';
    yield serializers.serialize(
      object.offensiveRebounds,
      specifiedType: const FullType(int),
    );
    yield r'defensiveRebounds';
    yield serializers.serialize(
      object.defensiveRebounds,
      specifiedType: const FullType(int),
    );
    yield r'turnovers';
    yield serializers.serialize(
      object.turnovers,
      specifiedType: const FullType(int),
    );
    yield r'steals';
    yield serializers.serialize(
      object.steals,
      specifiedType: const FullType(int),
    );
    yield r'blocks';
    yield serializers.serialize(
      object.blocks,
      specifiedType: const FullType(int),
    );
    yield r'personalFouls';
    yield serializers.serialize(
      object.personalFouls,
      specifiedType: const FullType(int),
    );
    yield r'technicalFouls';
    yield serializers.serialize(
      object.technicalFouls,
      specifiedType: const FullType(int),
    );
    yield r'unsportsmanlikeFouls';
    yield serializers.serialize(
      object.unsportsmanlikeFouls,
      specifiedType: const FullType(int),
    );
    yield r'secondsPlayed';
    yield serializers.serialize(
      object.secondsPlayed,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    StatLine object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required StatLineBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'points':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.points = valueDes;
          break;
        case r'fg1Made':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fg1Made = valueDes;
          break;
        case r'fg1Attempted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fg1Attempted = valueDes;
          break;
        case r'fg2Made':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fg2Made = valueDes;
          break;
        case r'fg2Attempted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fg2Attempted = valueDes;
          break;
        case r'fg3Made':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fg3Made = valueDes;
          break;
        case r'fg3Attempted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fg3Attempted = valueDes;
          break;
        case r'assists':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.assists = valueDes;
          break;
        case r'offensiveRebounds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.offensiveRebounds = valueDes;
          break;
        case r'defensiveRebounds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.defensiveRebounds = valueDes;
          break;
        case r'turnovers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.turnovers = valueDes;
          break;
        case r'steals':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.steals = valueDes;
          break;
        case r'blocks':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.blocks = valueDes;
          break;
        case r'personalFouls':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.personalFouls = valueDes;
          break;
        case r'technicalFouls':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.technicalFouls = valueDes;
          break;
        case r'unsportsmanlikeFouls':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.unsportsmanlikeFouls = valueDes;
          break;
        case r'secondsPlayed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.secondsPlayed = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  StatLine deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StatLineBuilder();
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


