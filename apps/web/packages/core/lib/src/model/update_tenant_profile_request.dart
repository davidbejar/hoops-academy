//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_tenant_profile_request.g.dart';

/// UpdateTenantProfileRequest
///
/// Properties:
/// * [name] 
/// * [timezone] 
/// * [defaultLocale] 
/// * [contactEmail] 
/// * [websiteUrl] 
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateTenantProfileRequest implements Built<UpdateTenantProfileRequest, UpdateTenantProfileRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'timezone')
  String? get timezone;

  @BuiltValueField(wireName: r'defaultLocale')
  Locale? get defaultLocale;
  // enum defaultLocaleEnum {  es,  en,  id,  };

  @BuiltValueField(wireName: r'contactEmail')
  String? get contactEmail;

  @BuiltValueField(wireName: r'websiteUrl')
  String? get websiteUrl;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateTenantProfileRequestClearEnum>? get clear;
  // enum clearEnum {  contactEmail,  websiteUrl,  };

  UpdateTenantProfileRequest._();

  factory UpdateTenantProfileRequest([void updates(UpdateTenantProfileRequestBuilder b)]) = _$UpdateTenantProfileRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTenantProfileRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTenantProfileRequest> get serializer => _$UpdateTenantProfileRequestSerializer();
}

class _$UpdateTenantProfileRequestSerializer implements PrimitiveSerializer<UpdateTenantProfileRequest> {
  @override
  final Iterable<Type> types = const [UpdateTenantProfileRequest, _$UpdateTenantProfileRequest];

  @override
  final String wireName = r'UpdateTenantProfileRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTenantProfileRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.timezone != null) {
      yield r'timezone';
      yield serializers.serialize(
        object.timezone,
        specifiedType: const FullType(String),
      );
    }
    if (object.defaultLocale != null) {
      yield r'defaultLocale';
      yield serializers.serialize(
        object.defaultLocale,
        specifiedType: const FullType(Locale),
      );
    }
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
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateTenantProfileRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTenantProfileRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTenantProfileRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.timezone = valueDes;
          break;
        case r'defaultLocale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Locale),
          ) as Locale?;
          if (valueDes == null) continue;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateTenantProfileRequestClearEnum)]),
          ) as BuiltSet<UpdateTenantProfileRequestClearEnum>?;
          if (valueDes == null) continue;
          result.clear.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTenantProfileRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTenantProfileRequestBuilder();
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


class UpdateTenantProfileRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'contactEmail')
  static const UpdateTenantProfileRequestClearEnum contactEmail = _$updateTenantProfileRequestClearEnum_contactEmail;
  @BuiltValueEnumConst(wireName: r'websiteUrl')
  static const UpdateTenantProfileRequestClearEnum websiteUrl = _$updateTenantProfileRequestClearEnum_websiteUrl;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateTenantProfileRequestClearEnum unknownDefaultOpenApi = _$updateTenantProfileRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateTenantProfileRequestClearEnum> get serializer => _$updateTenantProfileRequestClearEnumSerializer;

  const UpdateTenantProfileRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateTenantProfileRequestClearEnum> get values => _$updateTenantProfileRequestClearEnumValues;
  static UpdateTenantProfileRequestClearEnum valueOf(String name) => _$updateTenantProfileRequestClearEnumValueOf(name);
}

