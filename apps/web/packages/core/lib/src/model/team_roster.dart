//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/roster_staff.dart';
import 'package:hoops_core_api/src/model/roster_player.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_roster.g.dart';

/// TeamRoster
///
/// Properties:
/// * [tenantId]
/// * [teamId]
/// * [seasonId]
/// * [teamName]
/// * [players]
/// * [staff]
@BuiltValue()
abstract class TeamRoster implements Built<TeamRoster, TeamRosterBuilder> {
  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  @BuiltValueField(wireName: r'teamName')
  String get teamName;

  @BuiltValueField(wireName: r'players')
  BuiltList<RosterPlayer> get players;

  @BuiltValueField(wireName: r'staff')
  BuiltList<RosterStaff> get staff;

  TeamRoster._();

  factory TeamRoster([void updates(TeamRosterBuilder b)]) = _$TeamRoster;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamRosterBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TeamRoster> get serializer => _$TeamRosterSerializer();
}

class _$TeamRosterSerializer implements PrimitiveSerializer<TeamRoster> {
  @override
  final Iterable<Type> types = const [TeamRoster, _$TeamRoster];

  @override
  final String wireName = r'TeamRoster';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TeamRoster object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tenantId';
    yield serializers.serialize(
      object.tenantId,
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
    yield r'teamName';
    yield serializers.serialize(
      object.teamName,
      specifiedType: const FullType(String),
    );
    yield r'players';
    yield serializers.serialize(
      object.players,
      specifiedType: const FullType(BuiltList, [FullType(RosterPlayer)]),
    );
    yield r'staff';
    yield serializers.serialize(
      object.staff,
      specifiedType: const FullType(BuiltList, [FullType(RosterStaff)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TeamRoster object, {
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
    required TeamRosterBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tenantId = valueDes;
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
        case r'teamName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamName = valueDes;
          break;
        case r'players':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RosterPlayer)]),
          ) as BuiltList<RosterPlayer>;
          result.players.replace(valueDes);
          break;
        case r'staff':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RosterStaff)]),
          ) as BuiltList<RosterStaff>;
          result.staff.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TeamRoster deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamRosterBuilder();
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
