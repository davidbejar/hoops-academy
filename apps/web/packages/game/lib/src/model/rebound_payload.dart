//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'rebound_payload.g.dart';

/// ReboundPayload
///
/// Properties:
/// * [kind] 
@BuiltValue()
abstract class ReboundPayload implements Built<ReboundPayload, ReboundPayloadBuilder> {
  @BuiltValueField(wireName: r'kind')
  ReboundPayloadKindEnum get kind;
  // enum kindEnum {  OFFENSIVE,  DEFENSIVE,  };

  ReboundPayload._();

  factory ReboundPayload([void updates(ReboundPayloadBuilder b)]) = _$ReboundPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReboundPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReboundPayload> get serializer => _$ReboundPayloadSerializer();
}

class _$ReboundPayloadSerializer implements PrimitiveSerializer<ReboundPayload> {
  @override
  final Iterable<Type> types = const [ReboundPayload, _$ReboundPayload];

  @override
  final String wireName = r'ReboundPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReboundPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(ReboundPayloadKindEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReboundPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReboundPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReboundPayloadKindEnum),
          ) as ReboundPayloadKindEnum;
          result.kind = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReboundPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReboundPayloadBuilder();
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


class ReboundPayloadKindEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OFFENSIVE')
  static const ReboundPayloadKindEnum OFFENSIVE = _$reboundPayloadKindEnum_OFFENSIVE;
  @BuiltValueEnumConst(wireName: r'DEFENSIVE')
  static const ReboundPayloadKindEnum DEFENSIVE = _$reboundPayloadKindEnum_DEFENSIVE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ReboundPayloadKindEnum unknownDefaultOpenApi = _$reboundPayloadKindEnum_unknownDefaultOpenApi;

  static Serializer<ReboundPayloadKindEnum> get serializer => _$reboundPayloadKindEnumSerializer;

  const ReboundPayloadKindEnum._(String name): super(name);

  static BuiltSet<ReboundPayloadKindEnum> get values => _$reboundPayloadKindEnumValues;
  static ReboundPayloadKindEnum valueOf(String name) => _$reboundPayloadKindEnumValueOf(name);
}

