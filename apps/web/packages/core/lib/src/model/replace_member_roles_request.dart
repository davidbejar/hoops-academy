//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/tenant_role.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'replace_member_roles_request.g.dart';

/// ReplaceMemberRolesRequest
///
/// Properties:
/// * [roles] 
@BuiltValue()
abstract class ReplaceMemberRolesRequest implements Built<ReplaceMemberRolesRequest, ReplaceMemberRolesRequestBuilder> {
  @BuiltValueField(wireName: r'roles')
  BuiltSet<TenantRole> get roles;

  ReplaceMemberRolesRequest._();

  factory ReplaceMemberRolesRequest([void updates(ReplaceMemberRolesRequestBuilder b)]) = _$ReplaceMemberRolesRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReplaceMemberRolesRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReplaceMemberRolesRequest> get serializer => _$ReplaceMemberRolesRequestSerializer();
}

class _$ReplaceMemberRolesRequestSerializer implements PrimitiveSerializer<ReplaceMemberRolesRequest> {
  @override
  final Iterable<Type> types = const [ReplaceMemberRolesRequest, _$ReplaceMemberRolesRequest];

  @override
  final String wireName = r'ReplaceMemberRolesRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReplaceMemberRolesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'roles';
    yield serializers.serialize(
      object.roles,
      specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReplaceMemberRolesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReplaceMemberRolesRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'roles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(TenantRole)]),
          ) as BuiltSet<TenantRole>;
          result.roles.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReplaceMemberRolesRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReplaceMemberRolesRequestBuilder();
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


