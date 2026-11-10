//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/audit_action.dart';
import 'package:hoops_core_api/src/model/audit_actor.dart';
import 'package:hoops_core_api/src/model/audit_target.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_audit_event.g.dart';

/// An audit event and the academy it belongs to.
///
/// Properties:
/// * [id] 
/// * [at] 
/// * [action] 
/// * [actor] 
/// * [target] 
/// * [metadata] - Ids, role and enum names and the names of changed fields; never personal data.
/// * [tenantId] 
/// * [tenantName] 
@BuiltValue()
abstract class PlatformAuditEvent implements Built<PlatformAuditEvent, PlatformAuditEventBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'at')
  DateTime get at;

  @BuiltValueField(wireName: r'action')
  AuditAction get action;
  // enum actionEnum {  admin.added,  admin.removed,  admin.temporary_password_issued,  admin.updated,  approval.cancelled,  audit.exported,  guardian_link.created,  guardian_link.removed,  member.deactivated,  member.invitation_accepted,  member.invited,  member.login_email_changed,  member.roles_replaced,  member.temporary_password_expired,  member.temporary_password_issued,  member.updated,  player.approved,  player.rejected,  player.requested,  player.withdrawn,  team.roster_exported,  tenant.created,  tenant.events_backfilled,  tenant.logo_removed,  tenant.logo_replaced,  tenant.master_data_changed,  tenant.profile_changed,  tenant.reactivated,  tenant.request_accepted,  tenant.settings_changed,  tenant.suspended,  tenant.withdrawn,  };

  @BuiltValueField(wireName: r'actor')
  AuditActor get actor;

  @BuiltValueField(wireName: r'target')
  AuditTarget get target;

  /// Ids, role and enum names and the names of changed fields; never personal data.
  @BuiltValueField(wireName: r'metadata')
  BuiltMap<String, JsonObject?> get metadata;

  @BuiltValueField(wireName: r'tenantId')
  String get tenantId;

  @BuiltValueField(wireName: r'tenantName')
  String get tenantName;

  PlatformAuditEvent._();

  factory PlatformAuditEvent([void updates(PlatformAuditEventBuilder b)]) = _$PlatformAuditEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformAuditEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformAuditEvent> get serializer => _$PlatformAuditEventSerializer();
}

class _$PlatformAuditEventSerializer implements PrimitiveSerializer<PlatformAuditEvent> {
  @override
  final Iterable<Type> types = const [PlatformAuditEvent, _$PlatformAuditEvent];

  @override
  final String wireName = r'PlatformAuditEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformAuditEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'at';
    yield serializers.serialize(
      object.at,
      specifiedType: const FullType(DateTime),
    );
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(AuditAction),
    );
    yield r'actor';
    yield serializers.serialize(
      object.actor,
      specifiedType: const FullType(AuditActor),
    );
    yield r'target';
    yield serializers.serialize(
      object.target,
      specifiedType: const FullType(AuditTarget),
    );
    yield r'metadata';
    yield serializers.serialize(
      object.metadata,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
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
  }

  @override
  Object serialize(
    Serializers serializers,
    PlatformAuditEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlatformAuditEventBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.at = valueDes;
          break;
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuditAction),
          ) as AuditAction;
          result.action = valueDes;
          break;
        case r'actor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuditActor),
          ) as AuditActor;
          result.actor.replace(valueDes);
          break;
        case r'target':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuditTarget),
          ) as AuditTarget;
          result.target.replace(valueDes);
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.metadata.replace(valueDes);
          break;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlatformAuditEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformAuditEventBuilder();
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


