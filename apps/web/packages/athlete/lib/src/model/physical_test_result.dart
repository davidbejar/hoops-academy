//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/band_status.dart';
import 'package:hoops_athlete_api/src/model/norm_band.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:hoops_athlete_api/src/model/audit_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'physical_test_result.g.dart';

/// PhysicalTestResult
///
/// Properties:
/// * [recordedBy] 
/// * [recordedAt] 
/// * [id] 
/// * [playerId] 
/// * [testTypeId] 
/// * [testCode] 
/// * [unit] 
/// * [measuredOn] 
/// * [value] 
/// * [ageAtMeasurement] - Actual age (years) on measuredOn; null when core has no birth date for the player.
/// * [bandStatus] 
/// * [expectedBand] - Band for (gender, age at measurement, value); null when no norm covers the result.
/// * [normId] - Norm row that produced `expectedBand`.
/// * [referencePending] - The applied norm has no cited source yet (\"reference pending\" in the UI).
/// * [notes] 
@BuiltValue()
abstract class PhysicalTestResult implements AuditInfo, Built<PhysicalTestResult, PhysicalTestResultBuilder> {
  /// Band for (gender, age at measurement, value); null when no norm covers the result.
  @BuiltValueField(wireName: r'expectedBand')
  NormBand? get expectedBand;
  // enum expectedBandEnum {  POOR,  BELOW_AVERAGE,  AVERAGE,  ABOVE_AVERAGE,  EXCELLENT,  };

  @BuiltValueField(wireName: r'testCode')
  String get testCode;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  @BuiltValueField(wireName: r'measuredOn')
  Date get measuredOn;

  /// Actual age (years) on measuredOn; null when core has no birth date for the player.
  @BuiltValueField(wireName: r'ageAtMeasurement')
  int? get ageAtMeasurement;

  @BuiltValueField(wireName: r'bandStatus')
  BandStatus get bandStatus;
  // enum bandStatusEnum {  MATCHED,  NO_NORM,  MISSING_PLAYER_DATA,  };

  /// Norm row that produced `expectedBand`.
  @BuiltValueField(wireName: r'normId')
  String? get normId;

  @BuiltValueField(wireName: r'testTypeId')
  String get testTypeId;

  @BuiltValueField(wireName: r'unit')
  String get unit;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'value')
  double get value;

  /// The applied norm has no cited source yet (\"reference pending\" in the UI).
  @BuiltValueField(wireName: r'referencePending')
  bool get referencePending;

  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  PhysicalTestResult._();

  factory PhysicalTestResult([void updates(PhysicalTestResultBuilder b)]) = _$PhysicalTestResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhysicalTestResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhysicalTestResult> get serializer => _$PhysicalTestResultSerializer();
}

class _$PhysicalTestResultSerializer implements PrimitiveSerializer<PhysicalTestResult> {
  @override
  final Iterable<Type> types = const [PhysicalTestResult, _$PhysicalTestResult];

  @override
  final String wireName = r'PhysicalTestResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhysicalTestResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.expectedBand != null) {
      yield r'expectedBand';
      yield serializers.serialize(
        object.expectedBand,
        specifiedType: const FullType.nullable(NormBand),
      );
    }
    yield r'testCode';
    yield serializers.serialize(
      object.testCode,
      specifiedType: const FullType(String),
    );
    if (object.notes != null) {
      yield r'notes';
      yield serializers.serialize(
        object.notes,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'measuredOn';
    yield serializers.serialize(
      object.measuredOn,
      specifiedType: const FullType(Date),
    );
    yield r'ageAtMeasurement';
    yield object.ageAtMeasurement == null ? null : serializers.serialize(
      object.ageAtMeasurement,
      specifiedType: const FullType.nullable(int),
    );
    yield r'bandStatus';
    yield serializers.serialize(
      object.bandStatus,
      specifiedType: const FullType(BandStatus),
    );
    if (object.normId != null) {
      yield r'normId';
      yield serializers.serialize(
        object.normId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'testTypeId';
    yield serializers.serialize(
      object.testTypeId,
      specifiedType: const FullType(String),
    );
    yield r'unit';
    yield serializers.serialize(
      object.unit,
      specifiedType: const FullType(String),
    );
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
    yield r'value';
    yield serializers.serialize(
      object.value,
      specifiedType: const FullType(double),
    );
    yield r'referencePending';
    yield serializers.serialize(
      object.referencePending,
      specifiedType: const FullType(bool),
    );
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PhysicalTestResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhysicalTestResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'expectedBand':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(NormBand),
          ) as NormBand?;
          if (valueDes == null) continue;
          result.expectedBand = valueDes;
          break;
        case r'testCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.testCode = valueDes;
          break;
        case r'notes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.notes = valueDes;
          break;
        case r'measuredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.measuredOn = valueDes;
          break;
        case r'ageAtMeasurement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.ageAtMeasurement = valueDes;
          break;
        case r'bandStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BandStatus),
          ) as BandStatus;
          result.bandStatus = valueDes;
          break;
        case r'normId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.normId = valueDes;
          break;
        case r'testTypeId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.testTypeId = valueDes;
          break;
        case r'unit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.unit = valueDes;
          break;
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
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.value = valueDes;
          break;
        case r'referencePending':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.referencePending = valueDes;
          break;
        case r'playerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.playerId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhysicalTestResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhysicalTestResultBuilder();
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


