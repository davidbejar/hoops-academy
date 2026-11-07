//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/player_ref.dart';
import 'package:hoops_core_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'guardian_link_with_password.g.dart';

/// A guardian link and, when this call created the guardian's login, its temporary password.
///
/// Properties:
/// * [id]
/// * [guardian]
/// * [player]
/// * [createdAt]
/// * [temporaryPassword] - Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password).
@BuiltValue()
abstract class GuardianLinkWithPassword
    implements
        Built<GuardianLinkWithPassword, GuardianLinkWithPasswordBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'guardian')
  PersonRef get guardian;

  @BuiltValueField(wireName: r'player')
  PlayerRef get player;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  /// Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password).
  @BuiltValueField(wireName: r'temporaryPassword')
  String? get temporaryPassword;

  GuardianLinkWithPassword._();

  factory GuardianLinkWithPassword(
          [void updates(GuardianLinkWithPasswordBuilder b)]) =
      _$GuardianLinkWithPassword;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GuardianLinkWithPasswordBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GuardianLinkWithPassword> get serializer =>
      _$GuardianLinkWithPasswordSerializer();
}

class _$GuardianLinkWithPasswordSerializer
    implements PrimitiveSerializer<GuardianLinkWithPassword> {
  @override
  final Iterable<Type> types = const [
    GuardianLinkWithPassword,
    _$GuardianLinkWithPassword
  ];

  @override
  final String wireName = r'GuardianLinkWithPassword';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GuardianLinkWithPassword object, {
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
    if (object.temporaryPassword != null) {
      yield r'temporaryPassword';
      yield serializers.serialize(
        object.temporaryPassword,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GuardianLinkWithPassword object, {
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
    required GuardianLinkWithPasswordBuilder result,
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
        case r'temporaryPassword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.temporaryPassword = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GuardianLinkWithPassword deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GuardianLinkWithPasswordBuilder();
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
