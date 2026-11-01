//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/date.dart';
import 'package:hoops_core_api/src/model/gender.dart';
import 'package:hoops_core_api/src/model/player_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'player_brief.g.dart';

/// Minimal player information for other services (age/gender for norms, names for denormalisation).
///
/// Properties:
/// * [id] 
/// * [displayName] 
/// * [birthDate] 
/// * [gender] 
/// * [status] 
@BuiltValue()
abstract class PlayerBrief implements Built<PlayerBrief, PlayerBriefBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  @BuiltValueField(wireName: r'birthDate')
  Date get birthDate;

  @BuiltValueField(wireName: r'gender')
  Gender get gender;
  // enum genderEnum {  MALE,  FEMALE,  };

  @BuiltValueField(wireName: r'status')
  PlayerStatus get status;
  // enum statusEnum {  PENDING_APPROVAL,  ACTIVE,  ORPHAN,  WITHDRAWN,  };

  PlayerBrief._();

  factory PlayerBrief([void updates(PlayerBriefBuilder b)]) = _$PlayerBrief;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlayerBriefBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlayerBrief> get serializer => _$PlayerBriefSerializer();
}

class _$PlayerBriefSerializer implements PrimitiveSerializer<PlayerBrief> {
  @override
  final Iterable<Type> types = const [PlayerBrief, _$PlayerBrief];

  @override
  final String wireName = r'PlayerBrief';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlayerBrief object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
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
  }

  @override
  Object serialize(
    Serializers serializers,
    PlayerBrief object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlayerBriefBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlayerBrief deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlayerBriefBuilder();
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


