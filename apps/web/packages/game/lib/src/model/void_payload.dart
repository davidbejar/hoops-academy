//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'void_payload.g.dart';

/// VoidPayload
///
/// Properties:
/// * [targetEventId] - Event being voided (PARENT may only void own events).
@BuiltValue()
abstract class VoidPayload implements Built<VoidPayload, VoidPayloadBuilder> {
  /// Event being voided (PARENT may only void own events).
  @BuiltValueField(wireName: r'targetEventId')
  String get targetEventId;

  VoidPayload._();

  factory VoidPayload([void updates(VoidPayloadBuilder b)]) = _$VoidPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VoidPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VoidPayload> get serializer => _$VoidPayloadSerializer();
}

class _$VoidPayloadSerializer implements PrimitiveSerializer<VoidPayload> {
  @override
  final Iterable<Type> types = const [VoidPayload, _$VoidPayload];

  @override
  final String wireName = r'VoidPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VoidPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'targetEventId';
    yield serializers.serialize(
      object.targetEventId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VoidPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VoidPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'targetEventId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.targetEventId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VoidPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VoidPayloadBuilder();
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


