//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'authz_summary.g.dart';

/// The caller's scope within the tenant (what the UI may offer; the server re-checks every call).
///
/// Properties:
/// * [staffTeamIds] - Teams where the caller is COACH or ASSISTANT_COACH staff, without teams whose season has ended (in the academy's time zone) even while the staff row is still open (core 2.8.0). 
/// * [historicStaffTeamIds] - Teams of seasons that have ended (academy time zone) where the caller is still recorded as staff: their read-only history for a COACH / ASSISTANT_COACH (ADR-0042, core 3.2.0). Never overlaps `staffTeamIds`. 
/// * [linkedPlayerIds] - Players linked to the caller as guardian (PARENT).
/// * [ownPlayerId] - The caller's own player id when they hold the PLAYER role (null otherwise).
/// * [playerTeamIds] - Teams with a current (open, valid) assignment of the caller's own player (PLAYER) or of a linked player (PARENT); empty for other roles. Teams whose season has ended are left out even while the assignment is still open (core 2.8.0). 
/// * [timezone] - IANA time zone of the tenant (calendar days of sessions, birthdays, availability).
@BuiltValue()
abstract class AuthzSummary implements Built<AuthzSummary, AuthzSummaryBuilder> {
  /// Teams where the caller is COACH or ASSISTANT_COACH staff, without teams whose season has ended (in the academy's time zone) even while the staff row is still open (core 2.8.0). 
  @BuiltValueField(wireName: r'staffTeamIds')
  BuiltList<String> get staffTeamIds;

  /// Teams of seasons that have ended (academy time zone) where the caller is still recorded as staff: their read-only history for a COACH / ASSISTANT_COACH (ADR-0042, core 3.2.0). Never overlaps `staffTeamIds`. 
  @BuiltValueField(wireName: r'historicStaffTeamIds')
  BuiltList<String> get historicStaffTeamIds;

  /// Players linked to the caller as guardian (PARENT).
  @BuiltValueField(wireName: r'linkedPlayerIds')
  BuiltList<String> get linkedPlayerIds;

  /// The caller's own player id when they hold the PLAYER role (null otherwise).
  @BuiltValueField(wireName: r'ownPlayerId')
  String? get ownPlayerId;

  /// Teams with a current (open, valid) assignment of the caller's own player (PLAYER) or of a linked player (PARENT); empty for other roles. Teams whose season has ended are left out even while the assignment is still open (core 2.8.0). 
  @BuiltValueField(wireName: r'playerTeamIds')
  BuiltList<String> get playerTeamIds;

  /// IANA time zone of the tenant (calendar days of sessions, birthdays, availability).
  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  AuthzSummary._();

  factory AuthzSummary([void updates(AuthzSummaryBuilder b)]) = _$AuthzSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuthzSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuthzSummary> get serializer => _$AuthzSummarySerializer();
}

class _$AuthzSummarySerializer implements PrimitiveSerializer<AuthzSummary> {
  @override
  final Iterable<Type> types = const [AuthzSummary, _$AuthzSummary];

  @override
  final String wireName = r'AuthzSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuthzSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'staffTeamIds';
    yield serializers.serialize(
      object.staffTeamIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'historicStaffTeamIds';
    yield serializers.serialize(
      object.historicStaffTeamIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'linkedPlayerIds';
    yield serializers.serialize(
      object.linkedPlayerIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    if (object.ownPlayerId != null) {
      yield r'ownPlayerId';
      yield serializers.serialize(
        object.ownPlayerId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'playerTeamIds';
    yield serializers.serialize(
      object.playerTeamIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AuthzSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuthzSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'staffTeamIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.staffTeamIds.replace(valueDes);
          break;
        case r'historicStaffTeamIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.historicStaffTeamIds.replace(valueDes);
          break;
        case r'linkedPlayerIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.linkedPlayerIds.replace(valueDes);
          break;
        case r'ownPlayerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ownPlayerId = valueDes;
          break;
        case r'playerTeamIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.playerTeamIds.replace(valueDes);
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuthzSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuthzSummaryBuilder();
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


