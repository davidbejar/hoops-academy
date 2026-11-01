//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/physical_test_norm_input.dart';
import 'package:hoops_athlete_api/src/model/norm_band.dart';
import 'package:hoops_athlete_api/src/model/gender.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'physical_test_norm.g.dart';

/// PhysicalTestNorm
///
/// Properties:
/// * [testTypeId] 
/// * [gender] 
/// * [minAge] 
/// * [maxAge] - Inclusive.
/// * [band] 
/// * [minValue] 
/// * [maxValue] 
/// * [source_] - Citation of the reference the values come from.
/// * [id] 
/// * [global] - Platform-provided norm (tenant rows override it).
/// * [referencePending] - No source cited.
@BuiltValue()
abstract class PhysicalTestNorm implements PhysicalTestNormInput, Built<PhysicalTestNorm, PhysicalTestNormBuilder> {
  /// Platform-provided norm (tenant rows override it).
  @BuiltValueField(wireName: r'global')
  bool get global;

  @BuiltValueField(wireName: r'id')
  String get id;

  /// No source cited.
  @BuiltValueField(wireName: r'referencePending')
  bool get referencePending;

  PhysicalTestNorm._();

  factory PhysicalTestNorm([void updates(PhysicalTestNormBuilder b)]) = _$PhysicalTestNorm;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhysicalTestNormBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhysicalTestNorm> get serializer => _$PhysicalTestNormSerializer();
}

class _$PhysicalTestNormSerializer implements PrimitiveSerializer<PhysicalTestNorm> {
  @override
  final Iterable<Type> types = const [PhysicalTestNorm, _$PhysicalTestNorm];

  @override
  final String wireName = r'PhysicalTestNorm';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhysicalTestNorm object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'testTypeId';
    yield serializers.serialize(
      object.testTypeId,
      specifiedType: const FullType(String),
    );
    if (object.minValue != null) {
      yield r'minValue';
      yield serializers.serialize(
        object.minValue,
        specifiedType: const FullType.nullable(double),
      );
    }
    yield r'gender';
    yield serializers.serialize(
      object.gender,
      specifiedType: const FullType(Gender),
    );
    yield r'maxAge';
    yield serializers.serialize(
      object.maxAge,
      specifiedType: const FullType(int),
    );
    if (object.maxValue != null) {
      yield r'maxValue';
      yield serializers.serialize(
        object.maxValue,
        specifiedType: const FullType.nullable(double),
      );
    }
    yield r'minAge';
    yield serializers.serialize(
      object.minAge,
      specifiedType: const FullType(int),
    );
    if (object.source_ != null) {
      yield r'source';
      yield serializers.serialize(
        object.source_,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'global';
    yield serializers.serialize(
      object.global,
      specifiedType: const FullType(bool),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'band';
    yield serializers.serialize(
      object.band,
      specifiedType: const FullType(NormBand),
    );
    yield r'referencePending';
    yield serializers.serialize(
      object.referencePending,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PhysicalTestNorm object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhysicalTestNormBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'testTypeId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.testTypeId = valueDes;
          break;
        case r'minValue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.minValue = valueDes;
          break;
        case r'gender':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Gender),
          ) as Gender;
          result.gender = valueDes;
          break;
        case r'maxAge':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.maxAge = valueDes;
          break;
        case r'maxValue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.maxValue = valueDes;
          break;
        case r'minAge':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.minAge = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.source_ = valueDes;
          break;
        case r'global':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.global = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'band':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(NormBand),
          ) as NormBand;
          result.band = valueDes;
          break;
        case r'referencePending':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.referencePending = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhysicalTestNorm deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhysicalTestNormBuilder();
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


