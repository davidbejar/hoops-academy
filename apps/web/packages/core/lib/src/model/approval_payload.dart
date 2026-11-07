//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'approval_payload.g.dart';

/// Action parameters captured at request time.
///
/// Properties:
/// * [teamId]
/// * [jerseyNumber] - Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
/// * [note]
/// * [reason]
@BuiltValue()
abstract class ApprovalPayload
    implements Built<ApprovalPayload, ApprovalPayloadBuilder> {
  @BuiltValueField(wireName: r'teamId')
  String? get teamId;

  /// Jersey as printed (\"0\", \"00\" and \"7\" are different numbers).
  @BuiltValueField(wireName: r'jerseyNumber')
  String? get jerseyNumber;

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  ApprovalPayload._();

  factory ApprovalPayload([void updates(ApprovalPayloadBuilder b)]) =
      _$ApprovalPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ApprovalPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ApprovalPayload> get serializer =>
      _$ApprovalPayloadSerializer();
}

class _$ApprovalPayloadSerializer
    implements PrimitiveSerializer<ApprovalPayload> {
  @override
  final Iterable<Type> types = const [ApprovalPayload, _$ApprovalPayload];

  @override
  final String wireName = r'ApprovalPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ApprovalPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.teamId != null) {
      yield r'teamId';
      yield serializers.serialize(
        object.teamId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jerseyNumber != null) {
      yield r'jerseyNumber';
      yield serializers.serialize(
        object.jerseyNumber,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ApprovalPayload object, {
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
    required ApprovalPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'teamId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.teamId = valueDes;
          break;
        case r'jerseyNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jerseyNumber = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ApprovalPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ApprovalPayloadBuilder();
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
