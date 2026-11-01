//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'foul_payload.g.dart';

/// FoulPayload
///
/// Properties:
/// * [kind] 
@BuiltValue()
abstract class FoulPayload implements Built<FoulPayload, FoulPayloadBuilder> {
  @BuiltValueField(wireName: r'kind')
  FoulPayloadKindEnum get kind;
  // enum kindEnum {  PERSONAL,  TECHNICAL,  UNSPORTSMANLIKE,  };

  FoulPayload._();

  factory FoulPayload([void updates(FoulPayloadBuilder b)]) = _$FoulPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FoulPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FoulPayload> get serializer => _$FoulPayloadSerializer();
}

class _$FoulPayloadSerializer implements PrimitiveSerializer<FoulPayload> {
  @override
  final Iterable<Type> types = const [FoulPayload, _$FoulPayload];

  @override
  final String wireName = r'FoulPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FoulPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(FoulPayloadKindEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FoulPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FoulPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FoulPayloadKindEnum),
          ) as FoulPayloadKindEnum;
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
  FoulPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FoulPayloadBuilder();
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


class FoulPayloadKindEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PERSONAL')
  static const FoulPayloadKindEnum PERSONAL = _$foulPayloadKindEnum_PERSONAL;
  @BuiltValueEnumConst(wireName: r'TECHNICAL')
  static const FoulPayloadKindEnum TECHNICAL = _$foulPayloadKindEnum_TECHNICAL;
  @BuiltValueEnumConst(wireName: r'UNSPORTSMANLIKE')
  static const FoulPayloadKindEnum UNSPORTSMANLIKE = _$foulPayloadKindEnum_UNSPORTSMANLIKE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const FoulPayloadKindEnum unknownDefaultOpenApi = _$foulPayloadKindEnum_unknownDefaultOpenApi;

  static Serializer<FoulPayloadKindEnum> get serializer => _$foulPayloadKindEnumSerializer;

  const FoulPayloadKindEnum._(String name): super(name);

  static BuiltSet<FoulPayloadKindEnum> get values => _$foulPayloadKindEnumValues;
  static FoulPayloadKindEnum valueOf(String name) => _$foulPayloadKindEnumValueOf(name);
}

