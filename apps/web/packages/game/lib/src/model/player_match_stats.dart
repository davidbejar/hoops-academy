//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_game_api/src/model/stat_line.dart';
import 'package:hoops_game_api/src/model/projection_warning.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_match_stats.g.dart';

/// PlayerMatchStats
///
/// Properties:
/// * [playerId] 
/// * [displayName] 
/// * [jerseyNumber] 
/// * [wasStarter] 
/// * [stats] 
/// * [warnings] 
@BuiltValue()
abstract class PlayerMatchStats implements Built<PlayerMatchStats, PlayerMatchStatsBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  @BuiltValueField(wireName: r'wasStarter')
  bool get wasStarter;

  @BuiltValueField(wireName: r'stats')
  StatLine get stats;

  @BuiltValueField(wireName: r'warnings')
  BuiltList<ProjectionWarning> get warnings;

  PlayerMatchStats._();

  factory PlayerMatchStats([void updates(PlayerMatchStatsBuilder b)]) = _$PlayerMatchStats;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerMatchStatsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerMatchStats> get serializer => _$PlayerMatchStatsSerializer();
}

class _$PlayerMatchStatsSerializer implements PrimitiveSerializer<PlayerMatchStats> {
  @override
  final Iterable<Type> types = const [PlayerMatchStats, _$PlayerMatchStats];

  @override
  final String wireName = r'PlayerMatchStats';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerMatchStats object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'wasStarter';
    yield serializers.serialize(
      object.wasStarter,
      specifiedType: const FullType(bool),
    );
    yield r'stats';
    yield serializers.serialize(
      object.stats,
      specifiedType: const FullType(StatLine),
    );
    yield r'warnings';
    yield serializers.serialize(
      object.warnings,
      specifiedType: const FullType(BuiltList, [FullType(ProjectionWarning)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerMatchStats object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerMatchStatsBuilder result,
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
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
          break;
        case r'wasStarter':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.wasStarter = valueDes;
          break;
        case r'stats':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatLine),
          ) as StatLine;
          result.stats.replace(valueDes);
          break;
        case r'warnings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProjectionWarning)]),
          ) as BuiltList<ProjectionWarning>;
          result.warnings.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerMatchStats deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerMatchStatsBuilder();
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


