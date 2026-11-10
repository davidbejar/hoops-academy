//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/eligibility_case_resolution.dart';
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:hoops_core_api/src/model/team_ref.dart';
import 'package:hoops_core_api/src/model/eligibility_case_status.dart';
import 'package:hoops_core_api/src/model/person_ref.dart';
import 'package:hoops_core_api/src/model/eligibility_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_case.g.dart';

/// EligibilityCase
///
/// Properties:
/// * [id] 
/// * [player] 
/// * [team] 
/// * [reason] 
/// * [status] 
/// * [openedAt] 
/// * [resolvedAt] 
/// * [resolvedBy] 
/// * [resolution] 
/// * [resolutionNote] 
@BuiltValue()
abstract class EligibilityCase implements Built<EligibilityCase, EligibilityCaseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  @BuiltValueField(wireName: r'team')
  TeamRef get team;

  @BuiltValueField(wireName: r'reason')
  EligibilityReason get reason;
  // enum reasonEnum {  CATEGORY_TOO_LOW,  PLAY_UP_LIMIT_EXCEEDED,  GENDER_POLICY,  MISSING_BIRTH_DATE,  MISSING_GENDER,  PLAYER_NOT_ACTIVE,  };

  @BuiltValueField(wireName: r'status')
  EligibilityCaseStatus get status;
  // enum statusEnum {  OPEN,  RESOLVED,  };

  @BuiltValueField(wireName: r'openedAt')
  DateTime get openedAt;

  @BuiltValueField(wireName: r'resolvedAt')
  DateTime? get resolvedAt;

  @BuiltValueField(wireName: r'resolvedBy')
  PersonRef? get resolvedBy;

  @BuiltValueField(wireName: r'resolution')
  EligibilityCaseResolution? get resolution;
  // enum resolutionEnum {  REASSIGNED,  REMOVED_FROM_TEAM,  DISMISSED,  };

  @BuiltValueField(wireName: r'resolutionNote')
  String? get resolutionNote;

  EligibilityCase._();

  factory EligibilityCase([void updates(EligibilityCaseBuilder b)]) = _$EligibilityCase;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EligibilityCaseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EligibilityCase> get serializer => _$EligibilityCaseSerializer();
}

class _$EligibilityCaseSerializer implements PrimitiveSerializer<EligibilityCase> {
  @override
  final Iterable<Type> types = const [EligibilityCase, _$EligibilityCase];

  @override
  final String wireName = r'EligibilityCase';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EligibilityCase object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(PlayerRef),
    );
    yield r'team';
    yield serializers.serialize(
      object.team,
      specifiedType: const FullType(TeamRef),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(EligibilityReason),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(EligibilityCaseStatus),
    );
    yield r'openedAt';
    yield serializers.serialize(
      object.openedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.resolvedAt != null) {
      yield r'resolvedAt';
      yield serializers.serialize(
        object.resolvedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.resolvedBy != null) {
      yield r'resolvedBy';
      yield serializers.serialize(
        object.resolvedBy,
        specifiedType: const FullType.nullable(PersonRef),
      );
    }
    if (object.resolution != null) {
      yield r'resolution';
      yield serializers.serialize(
        object.resolution,
        specifiedType: const FullType.nullable(EligibilityCaseResolution),
      );
    }
    if (object.resolutionNote != null) {
      yield r'resolutionNote';
      yield serializers.serialize(
        object.resolutionNote,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EligibilityCase object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EligibilityCaseBuilder result,
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
        case r'player':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerRef),
          ) as PlayerRef;
          result.player.replace(valueDes);
          break;
        case r'team':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TeamRef),
          ) as TeamRef;
          result.team.replace(valueDes);
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EligibilityReason),
          ) as EligibilityReason;
          result.reason = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EligibilityCaseStatus),
          ) as EligibilityCaseStatus;
          result.status = valueDes;
          break;
        case r'openedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.openedAt = valueDes;
          break;
        case r'resolvedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.resolvedAt = valueDes;
          break;
        case r'resolvedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PersonRef),
          ) as PersonRef?;
          if (valueDes == null) continue;
          result.resolvedBy.replace(valueDes);
          break;
        case r'resolution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(EligibilityCaseResolution),
          ) as EligibilityCaseResolution?;
          if (valueDes == null) continue;
          result.resolution = valueDes;
          break;
        case r'resolutionNote':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resolutionNote = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EligibilityCase deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EligibilityCaseBuilder();
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


