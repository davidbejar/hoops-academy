//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/gender_policy.dart';
import 'package:hoops_core_api/src/model/age_category.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team.g.dart';

/// Team
///
/// Properties:
/// * [id] 
/// * [seasonId] 
/// * [seasonEnded] - The team's season has ended (academy time zone): the team is read-only history and every write on it answers 409 `SEASON_ENDED` (ADR-0042, core 3.2.0). 
/// * [name] 
/// * [alias] 
/// * [ageCategory] 
/// * [genderPolicy] 
/// * [playerCount] - Open, valid assignments.
@BuiltValue()
abstract class Team implements Built<Team, TeamBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  /// The team's season has ended (academy time zone): the team is read-only history and every write on it answers 409 `SEASON_ENDED` (ADR-0042, core 3.2.0). 
  @BuiltValueField(wireName: r'seasonEnded')
  bool get seasonEnded;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'alias')
  String? get alias;

  @BuiltValueField(wireName: r'ageCategory')
  AgeCategory get ageCategory;

  @BuiltValueField(wireName: r'genderPolicy')
  GenderPolicy get genderPolicy;
  // enum genderPolicyEnum {  MALE,  FEMALE,  MIXED,  };

  /// Open, valid assignments.
  @BuiltValueField(wireName: r'playerCount')
  int get playerCount;

  Team._();

  factory Team([void updates(TeamBuilder b)]) = _$Team;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Team> get serializer => _$TeamSerializer();
}

class _$TeamSerializer implements PrimitiveSerializer<Team> {
  @override
  final Iterable<Type> types = const [Team, _$Team];

  @override
  final String wireName = r'Team';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Team object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'seasonId';
    yield serializers.serialize(
      object.seasonId,
      specifiedType: const FullType(String),
    );
    yield r'seasonEnded';
    yield serializers.serialize(
      object.seasonEnded,
      specifiedType: const FullType(bool),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.alias != null) {
      yield r'alias';
      yield serializers.serialize(
        object.alias,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'ageCategory';
    yield serializers.serialize(
      object.ageCategory,
      specifiedType: const FullType(AgeCategory),
    );
    yield r'genderPolicy';
    yield serializers.serialize(
      object.genderPolicy,
      specifiedType: const FullType(GenderPolicy),
    );
    yield r'playerCount';
    yield serializers.serialize(
      object.playerCount,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Team object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TeamBuilder result,
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
        case r'seasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.seasonId = valueDes;
          break;
        case r'seasonEnded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.seasonEnded = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'alias':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.alias = valueDes;
          break;
        case r'ageCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AgeCategory),
          ) as AgeCategory;
          result.ageCategory.replace(valueDes);
          break;
        case r'genderPolicy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GenderPolicy),
          ) as GenderPolicy;
          result.genderPolicy = valueDes;
          break;
        case r'playerCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.playerCount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Team deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamBuilder();
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


