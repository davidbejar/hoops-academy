//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/team_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_team_assignment.g.dart';

/// PlayerTeamAssignment
///
/// Properties:
/// * [team]
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [playUpLevels]
/// * [valid] - False when the assignment was invalidated by the evaluator.
@BuiltValue()
abstract class PlayerTeamAssignment
    implements Built<PlayerTeamAssignment, PlayerTeamAssignmentBuilder> {
  @BuiltValueField(wireName: r'team')
  TeamRef get team;

  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  @BuiltValueField(wireName: r'playUpLevels')
  int get playUpLevels;

  /// False when the assignment was invalidated by the evaluator.
  @BuiltValueField(wireName: r'valid')
  bool get valid;

  PlayerTeamAssignment._();

  factory PlayerTeamAssignment([void updates(PlayerTeamAssignmentBuilder b)]) =
      _$PlayerTeamAssignment;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerTeamAssignmentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerTeamAssignment> get serializer =>
      _$PlayerTeamAssignmentSerializer();
}

class _$PlayerTeamAssignmentSerializer
    implements PrimitiveSerializer<PlayerTeamAssignment> {
  @override
  final Iterable<Type> types = const [
    PlayerTeamAssignment,
    _$PlayerTeamAssignment
  ];

  @override
  final String wireName = r'PlayerTeamAssignment';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerTeamAssignment object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'team';
    yield serializers.serialize(
      object.team,
      specifiedType: const FullType(TeamRef),
    );
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'playUpLevels';
    yield serializers.serialize(
      object.playUpLevels,
      specifiedType: const FullType(int),
    );
    yield r'valid';
    yield serializers.serialize(
      object.valid,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerTeamAssignment object, {
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
    required PlayerTeamAssignmentBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'team':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TeamRef),
          ) as TeamRef;
          result.team.replace(valueDes);
          break;
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
          break;
        case r'playUpLevels':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.playUpLevels = valueDes;
          break;
        case r'valid':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.valid = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerTeamAssignment deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerTeamAssignmentBuilder();
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
