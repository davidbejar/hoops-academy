//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/eligibility_check.dart';
import 'package:hoops_core_api/src/model/team.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligible_team.g.dart';

/// EligibleTeam
///
/// Properties:
/// * [team]
/// * [eligibility]
@BuiltValue()
abstract class EligibleTeam
    implements Built<EligibleTeam, EligibleTeamBuilder> {
  @BuiltValueField(wireName: r'team')
  Team get team;

  @BuiltValueField(wireName: r'eligibility')
  EligibilityCheck get eligibility;

  EligibleTeam._();

  factory EligibleTeam([void updates(EligibleTeamBuilder b)]) = _$EligibleTeam;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EligibleTeamBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EligibleTeam> get serializer => _$EligibleTeamSerializer();
}

class _$EligibleTeamSerializer implements PrimitiveSerializer<EligibleTeam> {
  @override
  final Iterable<Type> types = const [EligibleTeam, _$EligibleTeam];

  @override
  final String wireName = r'EligibleTeam';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EligibleTeam object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'team';
    yield serializers.serialize(
      object.team,
      specifiedType: const FullType(Team),
    );
    yield r'eligibility';
    yield serializers.serialize(
      object.eligibility,
      specifiedType: const FullType(EligibilityCheck),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EligibleTeam object, {
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
    required EligibleTeamBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'team':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Team),
          ) as Team;
          result.team.replace(valueDes);
          break;
        case r'eligibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EligibilityCheck),
          ) as EligibilityCheck;
          result.eligibility.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EligibleTeam deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EligibleTeamBuilder();
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
