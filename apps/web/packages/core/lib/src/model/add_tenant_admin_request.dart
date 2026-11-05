//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/locale.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'add_tenant_admin_request.g.dart';

/// AddTenantAdminRequest
///
/// Properties:
/// * [email] 
/// * [givenName] 
/// * [familyName] 
/// * [locale] 
@BuiltValue()
abstract class AddTenantAdminRequest implements Built<AddTenantAdminRequest, AddTenantAdminRequestBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'givenName')
  String get givenName;

  @BuiltValueField(wireName: r'familyName')
  String get familyName;

  @BuiltValueField(wireName: r'locale')
  Locale? get locale;
  // enum localeEnum {  es,  en,  id,  };

  AddTenantAdminRequest._();

  factory AddTenantAdminRequest([void updates(AddTenantAdminRequestBuilder b)]) = _$AddTenantAdminRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AddTenantAdminRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AddTenantAdminRequest> get serializer => _$AddTenantAdminRequestSerializer();
}

class _$AddTenantAdminRequestSerializer implements PrimitiveSerializer<AddTenantAdminRequest> {
  @override
  final Iterable<Type> types = const [AddTenantAdminRequest, _$AddTenantAdminRequest];

  @override
  final String wireName = r'AddTenantAdminRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AddTenantAdminRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'givenName';
    yield serializers.serialize(
      object.givenName,
      specifiedType: const FullType(String),
    );
    yield r'familyName';
    yield serializers.serialize(
      object.familyName,
      specifiedType: const FullType(String),
    );
    if (object.locale != null) {
      yield r'locale';
      yield serializers.serialize(
        object.locale,
        specifiedType: const FullType(Locale),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AddTenantAdminRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AddTenantAdminRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'givenName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.givenName = valueDes;
          break;
        case r'familyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.familyName = valueDes;
          break;
        case r'locale':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Locale),
          ) as Locale?;
          if (valueDes == null) continue;
          result.locale = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AddTenantAdminRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AddTenantAdminRequestBuilder();
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


