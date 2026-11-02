//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/invitation_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_admin.g.dart';

/// An administrator of a tenant as the platform sees it (identity only, ADR-0023).
///
/// Properties:
/// * [personId]
/// * [givenName]
/// * [familyName]
/// * [email]
/// * [invitationStatus]
/// * [otherRoles] - The person's tenant roles besides ADMIN (removing the administrator keeps these).
@BuiltValue()
abstract class TenantAdmin implements Built<TenantAdmin, TenantAdminBuilder> {
  @BuiltValueField(wireName: r'personId')
  String get personId;

  @BuiltValueField(wireName: r'givenName')
  String get givenName;

  @BuiltValueField(wireName: r'familyName')
  String get familyName;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'invitationStatus')
  InvitationStatus get invitationStatus;
  // enum invitationStatusEnum {  NONE,  PENDING,  ACCEPTED,  };

  /// The person's tenant roles besides ADMIN (removing the administrator keeps these).
  @BuiltValueField(wireName: r'otherRoles')
  BuiltSet<TenantRole> get otherRoles;

  TenantAdmin._();

  factory TenantAdmin([void updates(TenantAdminBuilder b)]) = _$TenantAdmin;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantAdminBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantAdmin> get serializer => _$TenantAdminSerializer();
}

class _$TenantAdminSerializer implements PrimitiveSerializer<TenantAdmin> {
  @override
  final Iterable<Type> types = const [TenantAdmin, _$TenantAdmin];

  @override
  final String wireName = r'TenantAdmin';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'personId';
    yield serializers.serialize(
      object.personId,
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
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'invitationStatus';
    yield serializers.serialize(
      object.invitationStatus,
      specifiedType: const FullType(InvitationStatus),
    );
    yield r'otherRoles';
    yield serializers.serialize(
      object.otherRoles,
      specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TenantAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantAdminBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
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
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.email = valueDes;
          break;
        case r'invitationStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InvitationStatus),
          ) as InvitationStatus;
          result.invitationStatus = valueDes;
          break;
        case r'otherRoles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
          ) as BuiltSet<TenantRole>;
          result.otherRoles.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TenantAdmin deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantAdminBuilder();
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
