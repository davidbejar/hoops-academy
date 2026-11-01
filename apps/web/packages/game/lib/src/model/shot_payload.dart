//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'shot_payload.g.dart';

/// ShotPayload
///
/// Properties:
/// * [points] - 1 = free throw, 2 = field goal, 3 = three-pointer.
/// * [made] 
@BuiltValue()
abstract class ShotPayload implements Built<ShotPayload, ShotPayloadBuilder> {
  /// 1 = free throw, 2 = field goal, 3 = three-pointer.
  @BuiltValueField(wireName: r'points')
  ShotPayloadPointsEnum get points;
  // enum pointsEnum {  1,  2,  3,  };

  @BuiltValueField(wireName: r'made')
  bool get made;

  ShotPayload._();

  factory ShotPayload([void updates(ShotPayloadBuilder b)]) = _$ShotPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ShotPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ShotPayload> get serializer => _$ShotPayloadSerializer();
}

class _$ShotPayloadSerializer implements PrimitiveSerializer<ShotPayload> {
  @override
  final Iterable<Type> types = const [ShotPayload, _$ShotPayload];

  @override
  final String wireName = r'ShotPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ShotPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'points';
    yield serializers.serialize(
      object.points,
      specifiedType: const FullType(ShotPayloadPointsEnum),
    );
    yield r'made';
    yield serializers.serialize(
      object.made,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ShotPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ShotPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'points':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ShotPayloadPointsEnum),
          ) as ShotPayloadPointsEnum;
          result.points = valueDes;
          break;
        case r'made':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.made = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ShotPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ShotPayloadBuilder();
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


/// 1 = free throw, 2 = field goal, 3 = three-pointer.
class ShotPayloadPointsEnum extends EnumClass {

  @BuiltValueEnumConst(wireNumber: 1)
  static const ShotPayloadPointsEnum number1 = _$shotPayloadPointsEnum_number1;
  @BuiltValueEnumConst(wireNumber: 2)
  static const ShotPayloadPointsEnum number2 = _$shotPayloadPointsEnum_number2;
  @BuiltValueEnumConst(wireNumber: 3)
  static const ShotPayloadPointsEnum number3 = _$shotPayloadPointsEnum_number3;
  @BuiltValueEnumConst(wireNumber: 11184809, fallback: true)
  static const ShotPayloadPointsEnum unknownDefaultOpenApi = _$shotPayloadPointsEnum_unknownDefaultOpenApi;

  static Serializer<ShotPayloadPointsEnum> get serializer => _$shotPayloadPointsEnumSerializer;

  const ShotPayloadPointsEnum._(String name): super(name);

  static BuiltSet<ShotPayloadPointsEnum> get values => _$shotPayloadPointsEnumValues;
  static ShotPayloadPointsEnum valueOf(String name) => _$shotPayloadPointsEnumValueOf(name);
}

