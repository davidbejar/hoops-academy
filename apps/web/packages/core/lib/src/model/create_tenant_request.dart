//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/first_admin.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_tenant_request.g.dart';

/// CreateTenantRequest
///
/// Properties:
/// * [slug] 
/// * [name] 
/// * [timezone] 
/// * [defaultLocale] 
/// * [firstAdmin] 
@BuiltValue()
abstract class CreateTenantRequest implements Built<CreateTenantRequest, CreateTenantRequestBuilder> {
  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'defaultLocale')
  Locale get defaultLocale;
  // enum defaultLocaleEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'firstAdmin')
  FirstAdmin get firstAdmin;

  CreateTenantRequest._();

  factory CreateTenantRequest([void updates(CreateTenantRequestBuilder b)]) = _$CreateTenantRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTenantRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTenantRequest> get serializer => _$CreateTenantRequestSerializer();
}

class _$CreateTenantRequestSerializer implements PrimitiveSerializer<CreateTenantRequest> {
  @override
  final Iterable<Type> types = const [CreateTenantRequest, _$CreateTenantRequest];

  @override
  final String wireName = r'CreateTenantRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTenantRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    yield r'firstAdmin';
    yield serializers.serialize(
      object.firstAdmin,
      specifiedType: const FullType(FirstAdmin),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTenantRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTenantRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'firstAdmin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FirstAdmin),
          ) as FirstAdmin;
          result.firstAdmin.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTenantRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTenantRequestBuilder();
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


