//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match_status.dart';
import 'package:hoops_game_api/src/model/score.dart';
import 'package:hoops_game_api/src/model/home_away.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match.g.dart';

/// Match
///
/// Properties:
/// * [id] 
/// * [teamId] 
/// * [seasonId] 
/// * [opponentName] 
/// * [homeAway] 
/// * [scheduledAt] 
/// * [venue] 
/// * [status] 
/// * [periodCount] 
/// * [periodMinutes] 
/// * [startedAt] 
/// * [finishedAt] 
/// * [cancelledAt] 
/// * [cancelReason] 
/// * [score] 
/// * [lastServerSeq] - Highest `serverSeq` stored for the match (0 = no events).
@BuiltValue()
abstract class Match implements Built<Match, MatchBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  @BuiltValueField(wireName: r'opponentName')
  String get opponentName;

  @BuiltValueField(wireName: r'homeAway')
  HomeAway get homeAway;
  // enum homeAwayEnum {  HOME,  AWAY,  };

  @BuiltValueField(wireName: r'scheduledAt')
  DateTime get scheduledAt;

  @BuiltValueField(wireName: r'venue')
  String? get venue;

  @BuiltValueField(wireName: r'status')
  MatchStatus get status;
  // enum statusEnum {  SCHEDULED,  LIVE,  FINISHED,  CANCELLED,  };

  @BuiltValueField(wireName: r'periodCount')
  int get periodCount;

  @BuiltValueField(wireName: r'periodMinutes')
  int get periodMinutes;

  @BuiltValueField(wireName: r'startedAt')
  DateTime? get startedAt;

  @BuiltValueField(wireName: r'finishedAt')
  DateTime? get finishedAt;

  @BuiltValueField(wireName: r'cancelledAt')
  DateTime? get cancelledAt;

  @BuiltValueField(wireName: r'cancelReason')
  String? get cancelReason;

  @BuiltValueField(wireName: r'score')
  Score get score;

  /// Highest `serverSeq` stored for the match (0 = no events).
  @BuiltValueField(wireName: r'lastServerSeq')
  int get lastServerSeq;

  Match._();

  factory Match([void updates(MatchBuilder b)]) = _$Match;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Match> get serializer => _$MatchSerializer();
}

class _$MatchSerializer implements PrimitiveSerializer<Match> {
  @override
  final Iterable<Type> types = const [Match, _$Match];

  @override
  final String wireName = r'Match';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Match object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'seasonId';
    yield serializers.serialize(
      object.seasonId,
      specifiedType: const FullType(String),
    );
    yield r'opponentName';
    yield serializers.serialize(
      object.opponentName,
      specifiedType: const FullType(String),
    );
    yield r'homeAway';
    yield serializers.serialize(
      object.homeAway,
      specifiedType: const FullType(HomeAway),
    );
    yield r'scheduledAt';
    yield serializers.serialize(
      object.scheduledAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.venue != null) {
      yield r'venue';
      yield serializers.serialize(
        object.venue,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MatchStatus),
    );
    yield r'periodCount';
    yield serializers.serialize(
      object.periodCount,
      specifiedType: const FullType(int),
    );
    yield r'periodMinutes';
    yield serializers.serialize(
      object.periodMinutes,
      specifiedType: const FullType(int),
    );
    if (object.startedAt != null) {
      yield r'startedAt';
      yield serializers.serialize(
        object.startedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.finishedAt != null) {
      yield r'finishedAt';
      yield serializers.serialize(
        object.finishedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.cancelledAt != null) {
      yield r'cancelledAt';
      yield serializers.serialize(
        object.cancelledAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.cancelReason != null) {
      yield r'cancelReason';
      yield serializers.serialize(
        object.cancelReason,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'score';
    yield serializers.serialize(
      object.score,
      specifiedType: const FullType(Score),
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
    Match object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'seasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.seasonId = valueDes;
          break;
        case r'opponentName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.opponentName = valueDes;
          break;
        case r'homeAway':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HomeAway),
          ) as HomeAway;
          result.homeAway = valueDes;
          break;
        case r'scheduledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scheduledAt = valueDes;
          break;
        case r'venue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.venue = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchStatus),
          ) as MatchStatus;
          result.status = valueDes;
          break;
        case r'periodCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.periodCount = valueDes;
          break;
        case r'periodMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.periodMinutes = valueDes;
          break;
        case r'startedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.startedAt = valueDes;
          break;
        case r'finishedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.finishedAt = valueDes;
          break;
        case r'cancelledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.cancelledAt = valueDes;
          break;
        case r'cancelReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cancelReason = valueDes;
          break;
        case r'score':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Score),
          ) as Score;
          result.score.replace(valueDes);
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
  Match deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchBuilder();
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


