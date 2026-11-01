//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'body_measurement_input.g.dart';

/// At least one of `heightCm` / `weightKg`.
///
/// Properties:
/// * [playerId] 
/// * [measuredOn] 
/// * [heightCm] 
/// * [weightKg] 
@BuiltValue()
abstract class BodyMeasurementInput implements Built<BodyMeasurementInput, BodyMeasurementInputBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'measuredOn')
  Date get measuredOn;

  @BuiltValueField(wireName: r'heightCm')
  double? get heightCm;

  @BuiltValueField(wireName: r'weightKg')
  double? get weightKg;

  BodyMeasurementInput._();

  factory BodyMeasurementInput([void updates(BodyMeasurementInputBuilder b)]) = _$BodyMeasurementInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BodyMeasurementInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BodyMeasurementInput> get serializer => _$BodyMeasurementInputSerializer();
}

class _$BodyMeasurementInputSerializer implements PrimitiveSerializer<BodyMeasurementInput> {
  @override
  final Iterable<Type> types = const [BodyMeasurementInput, _$BodyMeasurementInput];

  @override
  final String wireName = r'BodyMeasurementInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BodyMeasurementInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'measuredOn';
    yield serializers.serialize(
      object.measuredOn,
      specifiedType: const FullType(Date),
    );
    if (object.heightCm != null) {
      yield r'heightCm';
      yield serializers.serialize(
        object.heightCm,
        specifiedType: const FullType(double),
      );
    }
    if (object.weightKg != null) {
      yield r'weightKg';
      yield serializers.serialize(
        object.weightKg,
        specifiedType: const FullType(double),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BodyMeasurementInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BodyMeasurementInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        case r'measuredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.measuredOn = valueDes;
          break;
        case r'heightCm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.heightCm = valueDes;
          break;
        case r'weightKg':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.weightKg = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BodyMeasurementInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BodyMeasurementInputBuilder();
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


