//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_body_measurement_request.g.dart';

/// UpdateBodyMeasurementRequest
///
/// Properties:
/// * [measuredOn]
/// * [heightCm]
/// * [weightKg]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdateBodyMeasurementRequest implements Built<UpdateBodyMeasurementRequest, UpdateBodyMeasurementRequestBuilder> {
  @BuiltValueField(wireName: r'measuredOn')
  Date? get measuredOn;

  @BuiltValueField(wireName: r'heightCm')
  double? get heightCm;

  @BuiltValueField(wireName: r'weightKg')
  double? get weightKg;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdateBodyMeasurementRequestClearEnum>? get clear;
  // enum clearEnum {  heightCm,  weightKg,  };

  UpdateBodyMeasurementRequest._();

  factory UpdateBodyMeasurementRequest([void updates(UpdateBodyMeasurementRequestBuilder b)]) = _$UpdateBodyMeasurementRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateBodyMeasurementRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateBodyMeasurementRequest> get serializer => _$UpdateBodyMeasurementRequestSerializer();
}

class _$UpdateBodyMeasurementRequestSerializer implements PrimitiveSerializer<UpdateBodyMeasurementRequest> {
  @override
  final Iterable<Type> types = const [UpdateBodyMeasurementRequest, _$UpdateBodyMeasurementRequest];

  @override
  final String wireName = r'UpdateBodyMeasurementRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateBodyMeasurementRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.measuredOn != null) {
      yield r'measuredOn';
      yield serializers.serialize(
        object.measuredOn,
        specifiedType: const FullType(Date),
      );
    }
    if (object.heightCm != null) {
      yield r'heightCm';
      yield serializers.serialize(
        object.heightCm,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.weightKg != null) {
      yield r'weightKg';
      yield serializers.serialize(
        object.weightKg,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdateBodyMeasurementRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateBodyMeasurementRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateBodyMeasurementRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'measuredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdateBodyMeasurementRequestClearEnum)]),
          ) as BuiltSet<UpdateBodyMeasurementRequestClearEnum>?;
          if (valueDes == null) continue;
          result.clear.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateBodyMeasurementRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateBodyMeasurementRequestBuilder();
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


class UpdateBodyMeasurementRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'heightCm')
  static const UpdateBodyMeasurementRequestClearEnum heightCm = _$updateBodyMeasurementRequestClearEnum_heightCm;
  @BuiltValueEnumConst(wireName: r'weightKg')
  static const UpdateBodyMeasurementRequestClearEnum weightKg = _$updateBodyMeasurementRequestClearEnum_weightKg;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdateBodyMeasurementRequestClearEnum unknownDefaultOpenApi = _$updateBodyMeasurementRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdateBodyMeasurementRequestClearEnum> get serializer => _$updateBodyMeasurementRequestClearEnumSerializer;

  const UpdateBodyMeasurementRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdateBodyMeasurementRequestClearEnum> get values => _$updateBodyMeasurementRequestClearEnumValues;
  static UpdateBodyMeasurementRequestClearEnum valueOf(String name) => _$updateBodyMeasurementRequestClearEnumValueOf(name);
}
