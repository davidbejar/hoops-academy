//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/audit_target_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_target.g.dart';

/// AuditTarget
///
/// Properties:
/// * [type] 
/// * [id] 
/// * [displayName] - Name of the person, player or academy while it exists; null for other target types and for rows that no longer exist or are not resolved. 
@BuiltValue()
abstract class AuditTarget implements Built<AuditTarget, AuditTargetBuilder> {
  @BuiltValueField(wireName: r'type')
  AuditTargetType get type;
  // enum typeEnum {  person,  player,  tenant,  approval_request,  guardian_link,  team,  };

  @BuiltValueField(wireName: r'id')
  String get id;

  /// Name of the person, player or academy while it exists; null for other target types and for rows that no longer exist or are not resolved. 
  @BuiltValueField(wireName: r'displayName')
  String? get displayName;

  AuditTarget._();

  factory AuditTarget([void updates(AuditTargetBuilder b)]) = _$AuditTarget;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuditTargetBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuditTarget> get serializer => _$AuditTargetSerializer();
}

class _$AuditTargetSerializer implements PrimitiveSerializer<AuditTarget> {
  @override
  final Iterable<Type> types = const [AuditTarget, _$AuditTarget];

  @override
  final String wireName = r'AuditTarget';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuditTarget object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(AuditTargetType),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.displayName != null) {
      yield r'displayName';
      yield serializers.serialize(
        object.displayName,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AuditTarget object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuditTargetBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuditTargetType),
          ) as AuditTargetType;
          result.type = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.displayName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuditTarget deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuditTargetBuilder();
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


