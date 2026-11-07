//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/gender.dart';
import 'package:hoops_core_api/src/model/player_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'roster_player.g.dart';

/// RosterPlayer
///
/// Properties:
/// * [playerId]
/// * [displayName]
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [birthDate]
/// * [gender]
/// * [status]
@BuiltValue()
abstract class RosterPlayer
    implements Built<RosterPlayer, RosterPlayerBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  @BuiltValueField(wireName: r'birthDate')
  Date get birthDate;

  @BuiltValueField(wireName: r'gender')
  Gender get gender;
  // enum genderEnum {  MALE,  FEMALE,  };

  @BuiltValueField(wireName: r'status')
  PlayerStatus get status;
  // enum statusEnum {  PENDING_APPROVAL,  ACTIVE,  ORPHAN,  WITHDRAWN,  REJECTED,  };

  RosterPlayer._();

  factory RosterPlayer([void updates(RosterPlayerBuilder b)]) = _$RosterPlayer;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RosterPlayerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RosterPlayer> get serializer => _$RosterPlayerSerializer();
}

class _$RosterPlayerSerializer implements PrimitiveSerializer<RosterPlayer> {
  @override
  final Iterable<Type> types = const [RosterPlayer, _$RosterPlayer];

  @override
  final String wireName = r'RosterPlayer';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RosterPlayer object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
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
  }

  @override
  Object serialize(
    Serializers serializers,
    RosterPlayer object, {
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
    required RosterPlayerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RosterPlayer deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RosterPlayerBuilder();
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
