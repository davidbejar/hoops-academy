//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:hoops_core_api/src/model/tenant_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_user_membership.g.dart';

/// The login's person in one academy, as that academy stores it.
///
/// Properties:
/// * [tenantId]
/// * [tenantName]
/// * [tenantSlug]
/// * [tenantStatus]
/// * [personId]
/// * [givenName]
/// * [familyName]
/// * [roles]
/// * [active] - False once the academy deactivated the person.
@BuiltValue()
abstract class PlatformUserMembership
    implements Built<PlatformUserMembership, PlatformUserMembershipBuilder> {
  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'tenantName')
  String get tenantName;

  @BuiltValueField(wireName: r'tenantSlug')
  String get tenantSlug;

  @BuiltValueField(wireName: r'tenantStatus')
  TenantStatus get tenantStatus;
  // enum tenantStatusEnum {  ACTIVE,  SUSPENDED,  WITHDRAWN,  };

  @BuiltValueField(wireName: r'personId')
  String get personId;

  @BuiltValueField(wireName: r'givenName')
  String get givenName;

  @BuiltValueField(wireName: r'familyName')
  String get familyName;

  @BuiltValueField(wireName: r'roles')
  BuiltSet<TenantRole> get roles;

  /// False once the academy deactivated the person.
  @BuiltValueField(wireName: r'active')
  bool get active;

  PlatformUserMembership._();

  factory PlatformUserMembership(
          [void updates(PlatformUserMembershipBuilder b)]) =
      _$PlatformUserMembership;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformUserMembershipBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformUserMembership> get serializer =>
      _$PlatformUserMembershipSerializer();
}

class _$PlatformUserMembershipSerializer
    implements PrimitiveSerializer<PlatformUserMembership> {
  @override
  final Iterable<Type> types = const [
    PlatformUserMembership,
    _$PlatformUserMembership
  ];

  @override
  final String wireName = r'PlatformUserMembership';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformUserMembership object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tenantId';
    yield serializers.serialize(
      object.tenantId,
      specifiedType: const FullType(String),
    );
    yield r'tenantName';
    yield serializers.serialize(
      object.tenantName,
      specifiedType: const FullType(String),
    );
    yield r'tenantSlug';
    yield serializers.serialize(
      object.tenantSlug,
      specifiedType: const FullType(String),
    );
    yield r'tenantStatus';
    yield serializers.serialize(
      object.tenantStatus,
      specifiedType: const FullType(TenantStatus),
    );
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
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
    );
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlatformUserMembership object, {
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
    required PlatformUserMembershipBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tenantId = valueDes;
          break;
        case r'tenantName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tenantName = valueDes;
          break;
        case r'tenantSlug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tenantSlug = valueDes;
          break;
        case r'tenantStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TenantStatus),
          ) as TenantStatus;
          result.tenantStatus = valueDes;
          break;
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
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
          ) as BuiltSet<TenantRole>;
          result.roles.replace(valueDes);
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlatformUserMembership deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformUserMembershipBuilder();
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
