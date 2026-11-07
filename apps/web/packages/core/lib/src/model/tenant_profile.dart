//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_profile.g.dart';

/// TenantProfile
///
/// Properties:
/// * [id]
/// * [slug]
/// * [name]
/// * [timezone]
/// * [defaultLocale]
/// * [contactEmail]
/// * [websiteUrl]
/// * [hasLogo]
/// * [logoEtag]
@BuiltValue()
abstract class TenantProfile
    implements Built<TenantProfile, TenantProfileBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'defaultLocale')
  Locale get defaultLocale;
  // enum defaultLocaleEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'contactEmail')
  String? get contactEmail;

  @BuiltValueField(wireName: r'websiteUrl')
  String? get websiteUrl;

  @BuiltValueField(wireName: r'hasLogo')
  bool get hasLogo;

  @BuiltValueField(wireName: r'logoEtag')
  String? get logoEtag;

  TenantProfile._();

  factory TenantProfile([void updates(TenantProfileBuilder b)]) =
      _$TenantProfile;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantProfileBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantProfile> get serializer =>
      _$TenantProfileSerializer();
}

class _$TenantProfileSerializer implements PrimitiveSerializer<TenantProfile> {
  @override
  final Iterable<Type> types = const [TenantProfile, _$TenantProfile];

  @override
  final String wireName = r'TenantProfile';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantProfile object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'defaultLocale';
    yield serializers.serialize(
      object.defaultLocale,
      specifiedType: const FullType(Locale),
    );
    if (object.contactEmail != null) {
      yield r'contactEmail';
      yield serializers.serialize(
        object.contactEmail,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.websiteUrl != null) {
      yield r'websiteUrl';
      yield serializers.serialize(
        object.websiteUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'hasLogo';
    yield serializers.serialize(
      object.hasLogo,
      specifiedType: const FullType(bool),
    );
    if (object.logoEtag != null) {
      yield r'logoEtag';
      yield serializers.serialize(
        object.logoEtag,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantProfile object, {
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
    required TenantProfileBuilder result,
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
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        case r'defaultLocale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Locale),
          ) as Locale;
          result.defaultLocale = valueDes;
          break;
        case r'contactEmail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.contactEmail = valueDes;
          break;
        case r'websiteUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.websiteUrl = valueDes;
          break;
        case r'hasLogo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasLogo = valueDes;
          break;
        case r'logoEtag':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.logoEtag = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantProfile deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantProfileBuilder();
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
