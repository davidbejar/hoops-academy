//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'stat_averages.g.dart';

/// Per-game averages over games played.
///
/// Properties:
/// * [points] 
/// * [assists] 
/// * [rebounds] 
/// * [steals] 
/// * [blocks] 
/// * [turnovers] 
/// * [personalFouls] 
/// * [minutesPlayed] 
@BuiltValue()
abstract class StatAverages implements Built<StatAverages, StatAveragesBuilder> {
  @BuiltValueField(wireName: r'points')
  double get points;

  @BuiltValueField(wireName: r'assists')
  double get assists;

  @BuiltValueField(wireName: r'rebounds')
  double get rebounds;

  @BuiltValueField(wireName: r'steals')
  double get steals;

  @BuiltValueField(wireName: r'blocks')
  double get blocks;

  @BuiltValueField(wireName: r'turnovers')
  double get turnovers;

  @BuiltValueField(wireName: r'personalFouls')
  double get personalFouls;

  @BuiltValueField(wireName: r'minutesPlayed')
  double get minutesPlayed;

  StatAverages._();

  factory StatAverages([void updates(StatAveragesBuilder b)]) = _$StatAverages;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StatAveragesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StatAverages> get serializer => _$StatAveragesSerializer();
}

class _$StatAveragesSerializer implements PrimitiveSerializer<StatAverages> {
  @override
  final Iterable<Type> types = const [StatAverages, _$StatAverages];

  @override
  final String wireName = r'StatAverages';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StatAverages object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'points';
    yield serializers.serialize(
      object.points,
      specifiedType: const FullType(double),
    );
    yield r'assists';
    yield serializers.serialize(
      object.assists,
      specifiedType: const FullType(double),
    );
    yield r'rebounds';
    yield serializers.serialize(
      object.rebounds,
      specifiedType: const FullType(double),
    );
    yield r'steals';
    yield serializers.serialize(
      object.steals,
      specifiedType: const FullType(double),
    );
    yield r'blocks';
    yield serializers.serialize(
      object.blocks,
      specifiedType: const FullType(double),
    );
    yield r'turnovers';
    yield serializers.serialize(
      object.turnovers,
      specifiedType: const FullType(double),
    );
    yield r'personalFouls';
    yield serializers.serialize(
      object.personalFouls,
      specifiedType: const FullType(double),
    );
    yield r'minutesPlayed';
    yield serializers.serialize(
      object.minutesPlayed,
      specifiedType: const FullType(double),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    StatAverages object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required StatAveragesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'points':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.points = valueDes;
          break;
        case r'assists':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.assists = valueDes;
          break;
        case r'rebounds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.rebounds = valueDes;
          break;
        case r'steals':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.steals = valueDes;
          break;
        case r'blocks':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.blocks = valueDes;
          break;
        case r'turnovers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.turnovers = valueDes;
          break;
        case r'personalFouls':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.personalFouls = valueDes;
          break;
        case r'minutesPlayed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.minutesPlayed = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  StatAverages deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StatAveragesBuilder();
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


