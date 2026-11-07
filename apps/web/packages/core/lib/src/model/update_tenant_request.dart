//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_tenant_request.g.dart';

/// UpdateTenantRequest
///
/// Properties:
/// * [name]
/// * [timezone]
/// * [defaultLocale]
@BuiltValue()
abstract class UpdateTenantRequest
    implements Built<UpdateTenantRequest, UpdateTenantRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'timezone')
  String? get timezone;

  @BuiltValueField(wireName: r'defaultLocale')
  Locale? get defaultLocale;
  // enum defaultLocaleEnum {  es,  en,  id,  };

  UpdateTenantRequest._();

  factory UpdateTenantRequest([void updates(UpdateTenantRequestBuilder b)]) =
      _$UpdateTenantRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTenantRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTenantRequest> get serializer =>
      _$UpdateTenantRequestSerializer();
}

class _$UpdateTenantRequestSerializer
    implements PrimitiveSerializer<UpdateTenantRequest> {
  @override
  final Iterable<Type> types = const [
    UpdateTenantRequest,
    _$UpdateTenantRequest
  ];

  @override
  final String wireName = r'UpdateTenantRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTenantRequest object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTenantRequest object, {
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
    required UpdateTenantRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTenantRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTenantRequestBuilder();
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
