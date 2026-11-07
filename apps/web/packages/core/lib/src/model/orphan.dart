//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/team_ref.dart';
import 'package:hoops_core_api/src/model/eligibility_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'orphan.g.dart';

/// Orphan
///
/// Properties:
/// * [player]
/// * [previousTeam]
/// * [reasons]
@BuiltValue()
abstract class Orphan implements Built<Orphan, OrphanBuilder> {
  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  @BuiltValueField(wireName: r'previousTeam')
  TeamRef? get previousTeam;

  @BuiltValueField(wireName: r'reasons')
  BuiltList<EligibilityReason> get reasons;

  Orphan._();

  factory Orphan([void updates(OrphanBuilder b)]) = _$Orphan;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrphanBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Orphan> get serializer => _$OrphanSerializer();
}

class _$OrphanSerializer implements PrimitiveSerializer<Orphan> {
  @override
  final Iterable<Type> types = const [Orphan, _$Orphan];

  @override
  final String wireName = r'Orphan';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Orphan object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(PlayerRef),
    );
    if (object.previousTeam != null) {
      yield r'previousTeam';
      yield serializers.serialize(
        object.previousTeam,
        specifiedType: const FullType.nullable(TeamRef),
      );
    }
    yield r'reasons';
    yield serializers.serialize(
      object.reasons,
      specifiedType: const FullType(BuiltList, [FullType(EligibilityReason)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Orphan object, {
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
    required OrphanBuilder result,
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
        case r'previousTeam':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(TeamRef),
          ) as TeamRef?;
          if (valueDes == null) continue;
          result.previousTeam.replace(valueDes);
          break;
        case r'reasons':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(EligibilityReason)]),
          ) as BuiltList<EligibilityReason>;
          result.reasons.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Orphan deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrphanBuilder();
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
