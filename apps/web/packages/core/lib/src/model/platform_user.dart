//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/platform_user_membership.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_user.g.dart';

/// One login (core.app_user) and its person in every academy it belongs to (core 3.4.0).
///
/// Properties:
/// * [id] - The login, as `Me.userId` and `Member.userId`.
/// * [email] - The login's e-mail (its Keycloak username).
/// * [createdAt] 
/// * [memberships] 
@BuiltValue()
abstract class PlatformUser implements Built<PlatformUser, PlatformUserBuilder> {
  /// The login, as `Me.userId` and `Member.userId`.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// The login's e-mail (its Keycloak username).
  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'memberships')
  BuiltList<PlatformUserMembership> get memberships;

  PlatformUser._();

  factory PlatformUser([void updates(PlatformUserBuilder b)]) = _$PlatformUser;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformUserBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformUser> get serializer => _$PlatformUserSerializer();
}

class _$PlatformUserSerializer implements PrimitiveSerializer<PlatformUser> {
  @override
  final Iterable<Type> types = const [PlatformUser, _$PlatformUser];

  @override
  final String wireName = r'PlatformUser';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformUser object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'memberships';
    yield serializers.serialize(
      object.memberships,
      specifiedType: const FullType(BuiltList, [FullType(PlatformUserMembership)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlatformUser object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlatformUserBuilder result,
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
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'memberships':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlatformUserMembership)]),
          ) as BuiltList<PlatformUserMembership>;
          result.memberships.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlatformUser deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformUserBuilder();
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


