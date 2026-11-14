//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/authz_summary.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:hoops_core_api/src/model/tenant_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'membership.g.dart';

/// Membership
///
/// Properties:
/// * [tenant]
/// * [personId]
/// * [givenName] - The caller's given name as this academy stores the person (core 3.6.0, decision 84; `PATCH /me` with `tenantId` changes it). Always sent by core; optional in the schema so that a 3.5 response still parses.
/// * [familyName] - The caller's family name as this academy stores the person (core 3.6.0, decision 84). Always sent by core; optional in the schema, as `givenName`.
/// * [roles]
/// * [authz]
@BuiltValue()
abstract class Membership implements Built<Membership, MembershipBuilder> {
  @BuiltValueField(wireName: r'tenant')
  TenantSummary get tenant;

  @BuiltValueField(wireName: r'personId')
  String get personId;

  /// The caller's given name as this academy stores the person (core 3.6.0, decision 84; `PATCH /me` with `tenantId` changes it). Always sent by core; optional in the schema so that a 3.5 response still parses.
  @BuiltValueField(wireName: r'givenName')
  String? get givenName;

  /// The caller's family name as this academy stores the person (core 3.6.0, decision 84). Always sent by core; optional in the schema, as `givenName`.
  @BuiltValueField(wireName: r'familyName')
  String? get familyName;

  @BuiltValueField(wireName: r'roles')
  BuiltSet<TenantRole> get roles;

  @BuiltValueField(wireName: r'authz')
  AuthzSummary get authz;

  Membership._();

  factory Membership([void updates(MembershipBuilder b)]) = _$Membership;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MembershipBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Membership> get serializer => _$MembershipSerializer();
}

class _$MembershipSerializer implements PrimitiveSerializer<Membership> {
  @override
  final Iterable<Type> types = const [Membership, _$Membership];

  @override
  final String wireName = r'Membership';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Membership object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'tenant';
    yield serializers.serialize(
      object.tenant,
      specifiedType: const FullType(TenantSummary),
    );
    yield r'personId';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
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
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
    );
    yield r'authz';
    yield serializers.serialize(
      object.authz,
      specifiedType: const FullType(AuthzSummary),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Membership object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MembershipBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'tenant':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TenantSummary),
          ) as TenantSummary;
          result.tenant.replace(valueDes);
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
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
          ) as BuiltSet<TenantRole>;
          result.roles.replace(valueDes);
          break;
        case r'authz':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuthzSummary),
          ) as AuthzSummary;
          result.authz.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Membership deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MembershipBuilder();
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
