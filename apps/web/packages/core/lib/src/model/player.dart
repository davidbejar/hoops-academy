//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/gender.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/player_status.dart';
import 'package:hoops_core_api/src/model/player_team_assignment.dart';
import 'package:hoops_core_api/src/model/age_category.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player.g.dart';

/// Player
///
/// Properties:
/// * [id] 
/// * [personId] 
/// * [givenName] 
/// * [familyName] 
/// * [displayName] 
/// * [birthDate] 
/// * [gender] 
/// * [status] 
/// * [naturalCategory] - Lowest-ranked category the player qualifies for in the current season.
/// * [teams] - Open assignments.
/// * [createdAt] 
/// * [preferredJerseyNumber] - The number the player would like to wear (core 3.5.0, ADR-0048); a wish, not unique. A new assignment without a number takes it when it is free on the team. 
@BuiltValue()
abstract class Player implements Built<Player, PlayerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'personId')
  String get personId;

  @BuiltValueField(wireName: r'givenName')
  String get givenName;

  @BuiltValueField(wireName: r'familyName')
  String get familyName;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  @BuiltValueField(wireName: r'birthDate')
  Date get birthDate;

  @BuiltValueField(wireName: r'gender')
  Gender get gender;
  // enum genderEnum {  MALE,  FEMALE,  };

  @BuiltValueField(wireName: r'status')
  PlayerStatus get status;
  // enum statusEnum {  PENDING_APPROVAL,  ACTIVE,  ORPHAN,  WITHDRAWN,  REJECTED,  };

  /// Lowest-ranked category the player qualifies for in the current season.
  @BuiltValueField(wireName: r'naturalCategory')
  AgeCategory? get naturalCategory;

  /// Open assignments.
  @BuiltValueField(wireName: r'teams')
  BuiltList<PlayerTeamAssignment> get teams;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  /// The number the player would like to wear (core 3.5.0, ADR-0048); a wish, not unique. A new assignment without a number takes it when it is free on the team. 
  @BuiltValueField(wireName: r'preferredJerseyNumber')
  String? get preferredJerseyNumber;

  Player._();

  factory Player([void updates(PlayerBuilder b)]) = _$Player;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Player> get serializer => _$PlayerSerializer();
}

class _$PlayerSerializer implements PrimitiveSerializer<Player> {
  @override
  final Iterable<Type> types = const [Player, _$Player];

  @override
  final String wireName = r'Player';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Player object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'personId';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    yield r'givenName';
    yield serializers.serialize(
      object.givenName,
      specifiedType: const FullType(String),
    );
    yield r'familyName';
    yield serializers.serialize(
      object.familyName,
      specifiedType: const FullType(String),
    );
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'birthDate';
    yield serializers.serialize(
      object.birthDate,
      specifiedType: const FullType(Date),
    );
    yield r'gender';
    yield serializers.serialize(
      object.gender,
      specifiedType: const FullType(Gender),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(PlayerStatus),
    );
    if (object.naturalCategory != null) {
      yield r'naturalCategory';
      yield serializers.serialize(
        object.naturalCategory,
        specifiedType: const FullType.nullable(AgeCategory),
      );
    }
    yield r'teams';
    yield serializers.serialize(
      object.teams,
      specifiedType: const FullType(BuiltList, [FullType(PlayerTeamAssignment)]),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.preferredJerseyNumber != null) {
      yield r'preferredJerseyNumber';
      yield serializers.serialize(
        object.preferredJerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Player object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerBuilder result,
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
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
        case r'givenName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.givenName = valueDes;
          break;
        case r'familyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.familyName = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'birthDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.birthDate = valueDes;
          break;
        case r'gender':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Gender),
          ) as Gender;
          result.gender = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerStatus),
          ) as PlayerStatus;
          result.status = valueDes;
          break;
        case r'naturalCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(AgeCategory),
          ) as AgeCategory?;
          if (valueDes == null) continue;
          result.naturalCategory.replace(valueDes);
          break;
        case r'teams':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlayerTeamAssignment)]),
          ) as BuiltList<PlayerTeamAssignment>;
          result.teams.replace(valueDes);
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'preferredJerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.preferredJerseyNumber = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Player deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerBuilder();
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


