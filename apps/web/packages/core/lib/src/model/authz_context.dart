//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:hoops_core_api/src/model/tenant_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'authz_context.g.dart';

/// AuthzContext
///
/// Properties:
/// * [sub] 
/// * [personId] 
/// * [tenantId] 
/// * [tenantStatus] 
/// * [roles] 
/// * [staffTeamIds] 
/// * [linkedPlayerIds] 
/// * [ownPlayerId] - The subject's own player id when they hold the PLAYER role.
/// * [playerTeamIds] - Teams with an open, valid assignment of the own player or of a linked player.
/// * [timezone] - IANA time zone of the tenant.
@BuiltValue()
abstract class AuthzContext implements Built<AuthzContext, AuthzContextBuilder> {
  @BuiltValueField(wireName: r'sub')
  String get sub;

  @BuiltValueField(wireName: r'personId')
  String get personId;

  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'tenantStatus')
  TenantStatus get tenantStatus;
  // enum tenantStatusEnum {  ACTIVE,  SUSPENDED,  WITHDRAWN,  };

  @BuiltValueField(wireName: r'roles')
  BuiltSet<TenantRole> get roles;

  @BuiltValueField(wireName: r'staffTeamIds')
  BuiltList<String> get staffTeamIds;

  @BuiltValueField(wireName: r'linkedPlayerIds')
  BuiltList<String> get linkedPlayerIds;

  /// The subject's own player id when they hold the PLAYER role.
  @BuiltValueField(wireName: r'ownPlayerId')
  String? get ownPlayerId;

  /// Teams with an open, valid assignment of the own player or of a linked player.
  @BuiltValueField(wireName: r'playerTeamIds')
  BuiltList<String> get playerTeamIds;

  /// IANA time zone of the tenant.
  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  AuthzContext._();

  factory AuthzContext([void updates(AuthzContextBuilder b)]) = _$AuthzContext;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuthzContextBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuthzContext> get serializer => _$AuthzContextSerializer();
}

class _$AuthzContextSerializer implements PrimitiveSerializer<AuthzContext> {
  @override
  final Iterable<Type> types = const [AuthzContext, _$AuthzContext];

  @override
  final String wireName = r'AuthzContext';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuthzContext object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'sub';
    yield serializers.serialize(
      object.sub,
      specifiedType: const FullType(String),
    );
    yield r'personId';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    yield r'tenantId';
    yield serializers.serialize(
      object.tenantId,
      specifiedType: const FullType(String),
    );
    yield r'tenantStatus';
    yield serializers.serialize(
      object.tenantStatus,
      specifiedType: const FullType(TenantStatus),
    );
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
    );
    yield r'staffTeamIds';
    yield serializers.serialize(
      object.staffTeamIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'linkedPlayerIds';
    yield serializers.serialize(
      object.linkedPlayerIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    if (object.ownPlayerId != null) {
      yield r'ownPlayerId';
      yield serializers.serialize(
        object.ownPlayerId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'playerTeamIds';
    yield serializers.serialize(
      object.playerTeamIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AuthzContext object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuthzContextBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'sub':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sub = valueDes;
          break;
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
        case r'tenantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tenantId = valueDes;
          break;
        case r'tenantStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TenantStatus),
          ) as TenantStatus;
          result.tenantStatus = valueDes;
          break;
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
          ) as BuiltSet<TenantRole>;
          result.roles.replace(valueDes);
          break;
        case r'staffTeamIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.staffTeamIds.replace(valueDes);
          break;
        case r'linkedPlayerIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.linkedPlayerIds.replace(valueDes);
          break;
        case r'ownPlayerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ownPlayerId = valueDes;
          break;
        case r'playerTeamIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.playerTeamIds.replace(valueDes);
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuthzContext deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuthzContextBuilder();
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


