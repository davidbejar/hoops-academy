//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_game_api/src/model/player_match_line.dart';
import 'package:hoops_game_api/src/model/stat_averages.dart';
import 'package:hoops_game_api/src/model/stat_line.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_season_stats.g.dart';

/// PlayerSeasonStats
///
/// Properties:
/// * [playerId] 
/// * [seasonId] 
/// * [gamesPlayed] 
/// * [gamesStarted] 
/// * [totals] 
/// * [averages] 
/// * [matches] 
@BuiltValue()
abstract class PlayerSeasonStats implements Built<PlayerSeasonStats, PlayerSeasonStatsBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  @BuiltValueField(wireName: r'gamesPlayed')
  int get gamesPlayed;

  @BuiltValueField(wireName: r'gamesStarted')
  int get gamesStarted;

  @BuiltValueField(wireName: r'totals')
  StatLine get totals;

  @BuiltValueField(wireName: r'averages')
  StatAverages get averages;

  @BuiltValueField(wireName: r'matches')
  BuiltList<PlayerMatchLine> get matches;

  PlayerSeasonStats._();

  factory PlayerSeasonStats([void updates(PlayerSeasonStatsBuilder b)]) = _$PlayerSeasonStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerSeasonStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerSeasonStats> get serializer => _$PlayerSeasonStatsSerializer();
}

class _$PlayerSeasonStatsSerializer implements PrimitiveSerializer<PlayerSeasonStats> {
  @override
  final Iterable<Type> types = const [PlayerSeasonStats, _$PlayerSeasonStats];

  @override
  final String wireName = r'PlayerSeasonStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerSeasonStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'seasonId';
    yield serializers.serialize(
      object.seasonId,
      specifiedType: const FullType(String),
    );
    yield r'gamesPlayed';
    yield serializers.serialize(
      object.gamesPlayed,
      specifiedType: const FullType(int),
    );
    yield r'gamesStarted';
    yield serializers.serialize(
      object.gamesStarted,
      specifiedType: const FullType(int),
    );
    yield r'totals';
    yield serializers.serialize(
      object.totals,
      specifiedType: const FullType(StatLine),
    );
    yield r'averages';
    yield serializers.serialize(
      object.averages,
      specifiedType: const FullType(StatAverages),
    );
    yield r'matches';
    yield serializers.serialize(
      object.matches,
      specifiedType: const FullType(BuiltList, [FullType(PlayerMatchLine)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerSeasonStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerSeasonStatsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'seasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.seasonId = valueDes;
          break;
        case r'gamesPlayed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.gamesPlayed = valueDes;
          break;
        case r'gamesStarted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.gamesStarted = valueDes;
          break;
        case r'totals':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatLine),
          ) as StatLine;
          result.totals.replace(valueDes);
          break;
        case r'averages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatAverages),
          ) as StatAverages;
          result.averages.replace(valueDes);
          break;
        case r'matches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlayerMatchLine)]),
          ) as BuiltList<PlayerMatchLine>;
          result.matches.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerSeasonStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerSeasonStatsBuilder();
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


