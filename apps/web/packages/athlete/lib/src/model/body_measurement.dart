//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'body_measurement.g.dart';

/// BodyMeasurement
///
/// Properties:
/// * [recordedBy]
/// * [recordedAt]
/// * [id]
/// * [playerId]
/// * [measuredOn]
/// * [heightCm]
/// * [weightKg]
@BuiltValue()
abstract class BodyMeasurement implements Built<BodyMeasurement, BodyMeasurementBuilder> {
  @BuiltValueField(wireName: r'recordedBy')
  PersonRef get recordedBy;

  @BuiltValueField(wireName: r'recordedAt')
  DateTime get recordedAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'measuredOn')
  Date get measuredOn;

  @BuiltValueField(wireName: r'heightCm')
  double? get heightCm;

  @BuiltValueField(wireName: r'weightKg')
  double? get weightKg;

  BodyMeasurement._();

  factory BodyMeasurement([void updates(BodyMeasurementBuilder b)]) = _$BodyMeasurement;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BodyMeasurementBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BodyMeasurement> get serializer => _$BodyMeasurementSerializer();
}

class _$BodyMeasurementSerializer implements PrimitiveSerializer<BodyMeasurement> {
  @override
  final Iterable<Type> types = const [BodyMeasurement, _$BodyMeasurement];

  @override
  final String wireName = r'BodyMeasurement';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BodyMeasurement object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'recordedBy';
    yield serializers.serialize(
      object.recordedBy,
      specifiedType: const FullType(PersonRef),
    );
    yield r'recordedAt';
    yield serializers.serialize(
      object.recordedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
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
  }

  @override
  Object serialize(
    Serializers serializers,
    BodyMeasurement object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BodyMeasurementBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'recordedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PersonRef),
          ) as PersonRef;
          result.recordedBy.replace(valueDes);
          break;
        case r'recordedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.recordedAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
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
  BodyMeasurement deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BodyMeasurementBuilder();
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
