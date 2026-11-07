//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/tenant.dart';
import 'package:hoops_core_api/src/model/academy_request.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'academy_request_accepted.g.dart';

/// AcademyRequestAccepted
///
/// Properties:
/// * [request]
/// * [tenant]
/// * [temporaryPassword] - Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password).
@BuiltValue()
abstract class AcademyRequestAccepted
    implements Built<AcademyRequestAccepted, AcademyRequestAcceptedBuilder> {
  @BuiltValueField(wireName: r'request')
  AcademyRequest get request;

  @BuiltValueField(wireName: r'tenant')
  Tenant get tenant;

  /// Server-generated temporary password of the login this call created (or re-issued). Shown once, never stored: pass it on privately; the person signs in with their e-mail and this password and must then choose their own. Absent when the person already had a login (they sign in with their own password).
  @BuiltValueField(wireName: r'temporaryPassword')
  String? get temporaryPassword;

  AcademyRequestAccepted._();

  factory AcademyRequestAccepted(
          [void updates(AcademyRequestAcceptedBuilder b)]) =
      _$AcademyRequestAccepted;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcademyRequestAcceptedBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcademyRequestAccepted> get serializer =>
      _$AcademyRequestAcceptedSerializer();
}

class _$AcademyRequestAcceptedSerializer
    implements PrimitiveSerializer<AcademyRequestAccepted> {
  @override
  final Iterable<Type> types = const [
    AcademyRequestAccepted,
    _$AcademyRequestAccepted
  ];

  @override
  final String wireName = r'AcademyRequestAccepted';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcademyRequestAccepted object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'request';
    yield serializers.serialize(
      object.request,
      specifiedType: const FullType(AcademyRequest),
    );
    yield r'tenant';
    yield serializers.serialize(
      object.tenant,
      specifiedType: const FullType(Tenant),
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
    AcademyRequestAccepted object, {
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
    required AcademyRequestAcceptedBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'request':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AcademyRequest),
          ) as AcademyRequest;
          result.request.replace(valueDes);
          break;
        case r'tenant':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Tenant),
          ) as Tenant;
          result.tenant.replace(valueDes);
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
  AcademyRequestAccepted deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcademyRequestAcceptedBuilder();
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
