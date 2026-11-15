//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/player_due_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_due_status.g.dart';

/// TeamDueStatus
///
/// Properties:
/// * [teamId]
/// * [players]
@BuiltValue()
abstract class TeamDueStatus implements Built<TeamDueStatus, TeamDueStatusBuilder> {
  @BuiltValueField(wireName: r'teamId')
  String get teamId;

  @BuiltValueField(wireName: r'players')
  BuiltList<PlayerDueStatus> get players;

  TeamDueStatus._();

  factory TeamDueStatus([void updates(TeamDueStatusBuilder b)]) = _$TeamDueStatus;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamDueStatusBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TeamDueStatus> get serializer => _$TeamDueStatusSerializer();
}

class _$TeamDueStatusSerializer implements PrimitiveSerializer<TeamDueStatus> {
  @override
  final Iterable<Type> types = const [TeamDueStatus, _$TeamDueStatus];

  @override
  final String wireName = r'TeamDueStatus';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TeamDueStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'teamId';
    yield serializers.serialize(
      object.teamId,
      specifiedType: const FullType(String),
    );
    yield r'players';
    yield serializers.serialize(
      object.players,
      specifiedType: const FullType(BuiltList, [FullType(PlayerDueStatus)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TeamDueStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TeamDueStatusBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.teamId = valueDes;
          break;
        case r'players':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlayerDueStatus)]),
          ) as BuiltList<PlayerDueStatus>;
          result.players.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TeamDueStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamDueStatusBuilder();
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
