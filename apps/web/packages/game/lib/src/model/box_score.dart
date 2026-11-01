//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_game_api/src/model/match_status.dart';
import 'package:hoops_game_api/src/model/player_match_stats.dart';
import 'package:hoops_game_api/src/model/score.dart';
import 'package:hoops_game_api/src/model/period_score.dart';
import 'package:hoops_game_api/src/model/stat_line.dart';
import 'package:hoops_game_api/src/model/projection_warning.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'box_score.g.dart';

/// BoxScore
///
/// Properties:
/// * [matchId] 
/// * [status] 
/// * [score] 
/// * [periodScores] 
/// * [teamTotals] 
/// * [players] - Player lines visible to the caller.
/// * [warnings] - Match-level warnings (not attributable to a player).
/// * [lastServerSeq] - Projection is up to date with events up to this sequence number.
@BuiltValue()
abstract class BoxScore implements Built<BoxScore, BoxScoreBuilder> {
  @BuiltValueField(wireName: r'matchId')
  String get matchId;

  @BuiltValueField(wireName: r'status')
  MatchStatus get status;
  // enum statusEnum {  SCHEDULED,  LIVE,  FINISHED,  CANCELLED,  };

  @BuiltValueField(wireName: r'score')
  Score get score;

  @BuiltValueField(wireName: r'periodScores')
  BuiltList<PeriodScore> get periodScores;

  @BuiltValueField(wireName: r'teamTotals')
  StatLine get teamTotals;

  /// Player lines visible to the caller.
  @BuiltValueField(wireName: r'players')
  BuiltList<PlayerMatchStats> get players;

  /// Match-level warnings (not attributable to a player).
  @BuiltValueField(wireName: r'warnings')
  BuiltList<ProjectionWarning> get warnings;

  /// Projection is up to date with events up to this sequence number.
  @BuiltValueField(wireName: r'lastServerSeq')
  int get lastServerSeq;

  BoxScore._();

  factory BoxScore([void updates(BoxScoreBuilder b)]) = _$BoxScore;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BoxScoreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BoxScore> get serializer => _$BoxScoreSerializer();
}

class _$BoxScoreSerializer implements PrimitiveSerializer<BoxScore> {
  @override
  final Iterable<Type> types = const [BoxScore, _$BoxScore];

  @override
  final String wireName = r'BoxScore';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BoxScore object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'matchId';
    yield serializers.serialize(
      object.matchId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MatchStatus),
    );
    yield r'score';
    yield serializers.serialize(
      object.score,
      specifiedType: const FullType(Score),
    );
    yield r'periodScores';
    yield serializers.serialize(
      object.periodScores,
      specifiedType: const FullType(BuiltList, [FullType(PeriodScore)]),
    );
    yield r'teamTotals';
    yield serializers.serialize(
      object.teamTotals,
      specifiedType: const FullType(StatLine),
    );
    yield r'players';
    yield serializers.serialize(
      object.players,
      specifiedType: const FullType(BuiltList, [FullType(PlayerMatchStats)]),
    );
    yield r'warnings';
    yield serializers.serialize(
      object.warnings,
      specifiedType: const FullType(BuiltList, [FullType(ProjectionWarning)]),
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
    BoxScore object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BoxScoreBuilder result,
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchStatus),
          ) as MatchStatus;
          result.status = valueDes;
          break;
        case r'score':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Score),
          ) as Score;
          result.score.replace(valueDes);
          break;
        case r'periodScores':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PeriodScore)]),
          ) as BuiltList<PeriodScore>;
          result.periodScores.replace(valueDes);
          break;
        case r'teamTotals':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatLine),
          ) as StatLine;
          result.teamTotals.replace(valueDes);
          break;
        case r'players':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlayerMatchStats)]),
          ) as BuiltList<PlayerMatchStats>;
          result.players.replace(valueDes);
          break;
        case r'warnings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProjectionWarning)]),
          ) as BuiltList<ProjectionWarning>;
          result.warnings.replace(valueDes);
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
  BoxScore deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BoxScoreBuilder();
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


