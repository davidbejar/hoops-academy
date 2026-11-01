//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_status.dart';
import 'package:hoops_game_api/src/model/stat_line.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_match_line.g.dart';

/// PlayerMatchLine
///
/// Properties:
/// * [matchId] 
/// * [scheduledAt] 
/// * [opponentName] 
/// * [status] 
/// * [wasStarter] 
/// * [stats] 
@BuiltValue()
abstract class PlayerMatchLine implements Built<PlayerMatchLine, PlayerMatchLineBuilder> {
  @BuiltValueField(wireName: r'matchId')
  String get matchId;

  @BuiltValueField(wireName: r'scheduledAt')
  DateTime get scheduledAt;

  @BuiltValueField(wireName: r'opponentName')
  String get opponentName;

  @BuiltValueField(wireName: r'status')
  MatchStatus get status;
  // enum statusEnum {  SCHEDULED,  LIVE,  FINISHED,  CANCELLED,  };

  @BuiltValueField(wireName: r'wasStarter')
  bool get wasStarter;

  @BuiltValueField(wireName: r'stats')
  StatLine get stats;

  PlayerMatchLine._();

  factory PlayerMatchLine([void updates(PlayerMatchLineBuilder b)]) = _$PlayerMatchLine;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerMatchLineBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerMatchLine> get serializer => _$PlayerMatchLineSerializer();
}

class _$PlayerMatchLineSerializer implements PrimitiveSerializer<PlayerMatchLine> {
  @override
  final Iterable<Type> types = const [PlayerMatchLine, _$PlayerMatchLine];

  @override
  final String wireName = r'PlayerMatchLine';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerMatchLine object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'matchId';
    yield serializers.serialize(
      object.matchId,
      specifiedType: const FullType(String),
    );
    yield r'scheduledAt';
    yield serializers.serialize(
      object.scheduledAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'opponentName';
    yield serializers.serialize(
      object.opponentName,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MatchStatus),
    );
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
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerMatchLine object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerMatchLineBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'matchId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.matchId = valueDes;
          break;
        case r'scheduledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scheduledAt = valueDes;
          break;
        case r'opponentName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.opponentName = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchStatus),
          ) as MatchStatus;
          result.status = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerMatchLine deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerMatchLineBuilder();
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


