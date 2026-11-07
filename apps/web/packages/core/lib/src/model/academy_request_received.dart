//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'academy_request_received.g.dart';

/// AcademyRequestReceived
///
/// Properties:
/// * [status]
@BuiltValue()
abstract class AcademyRequestReceived
    implements Built<AcademyRequestReceived, AcademyRequestReceivedBuilder> {
  @BuiltValueField(wireName: r'status')
  AcademyRequestReceivedStatusEnum get status;
  // enum statusEnum {  RECEIVED,  };

  AcademyRequestReceived._();

  factory AcademyRequestReceived(
          [void updates(AcademyRequestReceivedBuilder b)]) =
      _$AcademyRequestReceived;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcademyRequestReceivedBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcademyRequestReceived> get serializer =>
      _$AcademyRequestReceivedSerializer();
}

class _$AcademyRequestReceivedSerializer
    implements PrimitiveSerializer<AcademyRequestReceived> {
  @override
  final Iterable<Type> types = const [
    AcademyRequestReceived,
    _$AcademyRequestReceived
  ];

  @override
  final String wireName = r'AcademyRequestReceived';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcademyRequestReceived object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(AcademyRequestReceivedStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AcademyRequestReceived object, {
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
    required AcademyRequestReceivedBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AcademyRequestReceivedStatusEnum),
          ) as AcademyRequestReceivedStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcademyRequestReceived deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcademyRequestReceivedBuilder();
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

class AcademyRequestReceivedStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'RECEIVED')
  static const AcademyRequestReceivedStatusEnum RECEIVED =
      _$academyRequestReceivedStatusEnum_RECEIVED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AcademyRequestReceivedStatusEnum unknownDefaultOpenApi =
      _$academyRequestReceivedStatusEnum_unknownDefaultOpenApi;

  static Serializer<AcademyRequestReceivedStatusEnum> get serializer =>
      _$academyRequestReceivedStatusEnumSerializer;

  const AcademyRequestReceivedStatusEnum._(String name) : super(name);

  static BuiltSet<AcademyRequestReceivedStatusEnum> get values =>
      _$academyRequestReceivedStatusEnumValues;
  static AcademyRequestReceivedStatusEnum valueOf(String name) =>
      _$academyRequestReceivedStatusEnumValueOf(name);
}
