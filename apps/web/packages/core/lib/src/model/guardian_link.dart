//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:hoops_core_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'guardian_link.g.dart';

/// GuardianLink
///
/// Properties:
/// * [id]
/// * [guardian]
/// * [player]
/// * [createdAt]
@BuiltValue()
abstract class GuardianLink
    implements Built<GuardianLink, GuardianLinkBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'guardian')
  PersonRef get guardian;

  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  GuardianLink._();

  factory GuardianLink([void updates(GuardianLinkBuilder b)]) = _$GuardianLink;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GuardianLinkBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GuardianLink> get serializer => _$GuardianLinkSerializer();
}

class _$GuardianLinkSerializer implements PrimitiveSerializer<GuardianLink> {
  @override
  final Iterable<Type> types = const [GuardianLink, _$GuardianLink];

  @override
  final String wireName = r'GuardianLink';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GuardianLink object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'guardian';
    yield serializers.serialize(
      object.guardian,
      specifiedType: const FullType(PersonRef),
    );
    yield r'player';
    yield serializers.serialize(
      object.player,
      specifiedType: const FullType(PlayerRef),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GuardianLink object, {
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
    required GuardianLinkBuilder result,
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
        case r'guardian':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.guardian.replace(valueDes);
          break;
        case r'player':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlayerRef),
          ) as PlayerRef;
          result.player.replace(valueDes);
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GuardianLink deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GuardianLinkBuilder();
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
