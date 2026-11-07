//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/audit_actor_kind.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_actor.g.dart';

/// AuditActor
///
/// Properties:
/// * [kind]
/// * [subject] - The login (token subject) that acted, or `system`; null when the actor is masked for the caller (platform actors seen from an academy).
/// * [personId]
/// * [displayName] - Given and family name of the person while the person exists; null when not resolved.
@BuiltValue()
abstract class AuditActor implements Built<AuditActor, AuditActorBuilder> {
  @BuiltValueField(wireName: r'kind')
  AuditActorKind get kind;
  // enum kindEnum {  PERSON,  PLATFORM,  SYSTEM,  };

  /// The login (token subject) that acted, or `system`; null when the actor is masked for the caller (platform actors seen from an academy).
  @BuiltValueField(wireName: r'subject')
  String? get subject;

  @BuiltValueField(wireName: r'personId')
  String? get personId;

  /// Given and family name of the person while the person exists; null when not resolved.
  @BuiltValueField(wireName: r'displayName')
  String? get displayName;

  AuditActor._();

  factory AuditActor([void updates(AuditActorBuilder b)]) = _$AuditActor;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuditActorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuditActor> get serializer => _$AuditActorSerializer();
}

class _$AuditActorSerializer implements PrimitiveSerializer<AuditActor> {
  @override
  final Iterable<Type> types = const [AuditActor, _$AuditActor];

  @override
  final String wireName = r'AuditActor';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuditActor object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(AuditActorKind),
    );
    yield r'subject';
    yield object.subject == null
        ? null
        : serializers.serialize(
            object.subject,
            specifiedType: const FullType.nullable(String),
          );
    if (object.personId != null) {
      yield r'personId';
      yield serializers.serialize(
        object.personId,
        specifiedType: const FullType.nullable(String),
      );
    }
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
    AuditActor object, {
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
    required AuditActorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AuditActorKind),
          ) as AuditActorKind;
          result.kind = valueDes;
          break;
        case r'subject':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.subject = valueDes;
          break;
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.personId = valueDes;
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
  AuditActor deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuditActorBuilder();
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
