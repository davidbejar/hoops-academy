//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_tenant_admin_request.g.dart';

/// UpdateTenantAdminRequest
///
/// Properties:
/// * [givenName] 
/// * [familyName] 
/// * [email] 
@BuiltValue()
abstract class UpdateTenantAdminRequest implements Built<UpdateTenantAdminRequest, UpdateTenantAdminRequestBuilder> {
  @BuiltValueField(wireName: r'givenName')
  String? get givenName;

  @BuiltValueField(wireName: r'familyName')
  String? get familyName;

  @BuiltValueField(wireName: r'email')
  String? get email;

  UpdateTenantAdminRequest._();

  factory UpdateTenantAdminRequest([void updates(UpdateTenantAdminRequestBuilder b)]) = _$UpdateTenantAdminRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTenantAdminRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTenantAdminRequest> get serializer => _$UpdateTenantAdminRequestSerializer();
}

class _$UpdateTenantAdminRequestSerializer implements PrimitiveSerializer<UpdateTenantAdminRequest> {
  @override
  final Iterable<Type> types = const [UpdateTenantAdminRequest, _$UpdateTenantAdminRequest];

  @override
  final String wireName = r'UpdateTenantAdminRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTenantAdminRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.givenName != null) {
      yield r'givenName';
      yield serializers.serialize(
        object.givenName,
        specifiedType: const FullType(String),
      );
    }
    if (object.familyName != null) {
      yield r'familyName';
      yield serializers.serialize(
        object.familyName,
        specifiedType: const FullType(String),
      );
    }
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTenantAdminRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTenantAdminRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'givenName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.givenName = valueDes;
          break;
        case r'familyName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.familyName = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTenantAdminRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTenantAdminRequestBuilder();
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


