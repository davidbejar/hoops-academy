//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'timeout_payload.g.dart';

/// TimeoutPayload
///
/// Properties:
/// * [side] 
@BuiltValue()
abstract class TimeoutPayload implements Built<TimeoutPayload, TimeoutPayloadBuilder> {
  @BuiltValueField(wireName: r'side')
  TimeoutPayloadSideEnum get side;
  // enum sideEnum {  OWN,  OPPONENT,  };

  TimeoutPayload._();

  factory TimeoutPayload([void updates(TimeoutPayloadBuilder b)]) = _$TimeoutPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TimeoutPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TimeoutPayload> get serializer => _$TimeoutPayloadSerializer();
}

class _$TimeoutPayloadSerializer implements PrimitiveSerializer<TimeoutPayload> {
  @override
  final Iterable<Type> types = const [TimeoutPayload, _$TimeoutPayload];

  @override
  final String wireName = r'TimeoutPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TimeoutPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'side';
    yield serializers.serialize(
      object.side,
      specifiedType: const FullType(TimeoutPayloadSideEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TimeoutPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TimeoutPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'side':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TimeoutPayloadSideEnum),
          ) as TimeoutPayloadSideEnum;
          result.side = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TimeoutPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TimeoutPayloadBuilder();
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


class TimeoutPayloadSideEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWN')
  static const TimeoutPayloadSideEnum OWN = _$timeoutPayloadSideEnum_OWN;
  @BuiltValueEnumConst(wireName: r'OPPONENT')
  static const TimeoutPayloadSideEnum OPPONENT = _$timeoutPayloadSideEnum_OPPONENT;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TimeoutPayloadSideEnum unknownDefaultOpenApi = _$timeoutPayloadSideEnum_unknownDefaultOpenApi;

  static Serializer<TimeoutPayloadSideEnum> get serializer => _$timeoutPayloadSideEnumSerializer;

  const TimeoutPayloadSideEnum._(String name): super(name);

  static BuiltSet<TimeoutPayloadSideEnum> get values => _$timeoutPayloadSideEnumValues;
  static TimeoutPayloadSideEnum valueOf(String name) => _$timeoutPayloadSideEnumValueOf(name);
}

