//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/membership.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'me.g.dart';

/// Me
///
/// Properties:
/// * [userId]
/// * [sub] - Keycloak subject.
/// * [email]
/// * [displayName]
/// * [locale]
/// * [superAdmin] - Holds the platform realm role `super_admin`.
/// * [memberships] - Active memberships in ACTIVE tenants.
@BuiltValue()
abstract class Me implements Built<Me, MeBuilder> {
  @BuiltValueField(wireName: r'userId')
  String get userId;

  /// Keycloak subject.
  @BuiltValueField(wireName: r'sub')
  String get sub;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  @BuiltValueField(wireName: r'locale')
  Locale get locale;
  // enum localeEnum {  es,  en,  id,  };

  /// Holds the platform realm role `super_admin`.
  @BuiltValueField(wireName: r'superAdmin')
  bool get superAdmin;

  /// Active memberships in ACTIVE tenants.
  @BuiltValueField(wireName: r'memberships')
  BuiltList<Membership> get memberships;

  Me._();

  factory Me([void updates(MeBuilder b)]) = _$Me;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Me> get serializer => _$MeSerializer();
}

class _$MeSerializer implements PrimitiveSerializer<Me> {
  @override
  final Iterable<Type> types = const [Me, _$Me];

  @override
  final String wireName = r'Me';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Me object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'sub';
    yield serializers.serialize(
      object.sub,
      specifiedType: const FullType(String),
    );
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
    yield r'locale';
    yield serializers.serialize(
      object.locale,
      specifiedType: const FullType(Locale),
    );
    yield r'superAdmin';
    yield serializers.serialize(
      object.superAdmin,
      specifiedType: const FullType(bool),
    );
    yield r'memberships';
    yield serializers.serialize(
      object.memberships,
      specifiedType: const FullType(BuiltList, [FullType(Membership)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Me object, {
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
    required MeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'sub':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sub = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Locale),
          ) as Locale;
          result.locale = valueDes;
          break;
        case r'superAdmin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.superAdmin = valueDes;
          break;
        case r'memberships':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Membership)]),
          ) as BuiltList<Membership>;
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
  Me deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MeBuilder();
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
