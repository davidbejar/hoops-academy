//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:hoops_core_api/src/model/player_status.dart';
import 'package:hoops_core_api/src/model/eligibility_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_player.g.dart';

/// A player's assignment to a team (team_player).
///
/// Properties:
/// * [player]
/// * [teamId]
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [joinedOn]
/// * [leftOn]
/// * [playUpLevels] - 0 = natural category; n > 0 = playing up n categories.
/// * [invalidatedAt] - Set when the evaluator found the assignment no longer valid (never deleted).
/// * [invalidReason]
/// * [playerStatus]
@BuiltValue()
abstract class TeamPlayer implements Built<TeamPlayer, TeamPlayerBuilder> {
  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  @BuiltValueField(wireName: r'joinedOn')
  Date get joinedOn;

  @BuiltValueField(wireName: r'leftOn')
  Date? get leftOn;

  /// 0 = natural category; n > 0 = playing up n categories.
  @BuiltValueField(wireName: r'playUpLevels')
  int get playUpLevels;

  /// Set when the evaluator found the assignment no longer valid (never deleted).
  @BuiltValueField(wireName: r'invalidatedAt')
  DateTime? get invalidatedAt;

  @BuiltValueField(wireName: r'invalidReason')
  EligibilityReason? get invalidReason;
  // enum invalidReasonEnum {  CATEGORY_TOO_LOW,  PLAY_UP_LIMIT_EXCEEDED,  GENDER_POLICY,  MISSING_BIRTH_DATE,  MISSING_GENDER,  PLAYER_NOT_ACTIVE,  };

  @BuiltValueField(wireName: r'playerStatus')
  PlayerStatus get playerStatus;
  // enum playerStatusEnum {  PENDING_APPROVAL,  ACTIVE,  ORPHAN,  WITHDRAWN,  REJECTED,  };

  TeamPlayer._();

  factory TeamPlayer([void updates(TeamPlayerBuilder b)]) = _$TeamPlayer;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamPlayerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TeamPlayer> get serializer => _$TeamPlayerSerializer();
}

class _$TeamPlayerSerializer implements PrimitiveSerializer<TeamPlayer> {
  @override
  final Iterable<Type> types = const [TeamPlayer, _$TeamPlayer];

  @override
  final String wireName = r'TeamPlayer';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TeamPlayer object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(PlayerRef),
    );
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'joinedOn';
    yield serializers.serialize(
      object.joinedOn,
      specifiedType: const FullType(Date),
    );
    if (object.leftOn != null) {
      yield r'leftOn';
      yield serializers.serialize(
        object.leftOn,
        specifiedType: const FullType.nullable(Date),
      );
    }
    yield r'playUpLevels';
    yield serializers.serialize(
      object.playUpLevels,
      specifiedType: const FullType(int),
    );
    if (object.invalidatedAt != null) {
      yield r'invalidatedAt';
      yield serializers.serialize(
        object.invalidatedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.invalidReason != null) {
      yield r'invalidReason';
      yield serializers.serialize(
        object.invalidReason,
        specifiedType: const FullType.nullable(EligibilityReason),
      );
    }
    yield r'playerStatus';
    yield serializers.serialize(
      object.playerStatus,
      specifiedType: const FullType(PlayerStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TeamPlayer object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TeamPlayerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'player':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerRef),
          ) as PlayerRef;
          result.player.replace(valueDes);
          break;
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
          break;
        case r'joinedOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.joinedOn = valueDes;
          break;
        case r'leftOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.leftOn = valueDes;
          break;
        case r'playUpLevels':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.playUpLevels = valueDes;
          break;
        case r'invalidatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.invalidatedAt = valueDes;
          break;
        case r'invalidReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(EligibilityReason),
          ) as EligibilityReason?;
          if (valueDes == null) continue;
          result.invalidReason = valueDes;
          break;
        case r'playerStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerStatus),
          ) as PlayerStatus;
          result.playerStatus = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TeamPlayer deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamPlayerBuilder();
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
