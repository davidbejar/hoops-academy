//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'physical_test_result_input.g.dart';

/// PhysicalTestResultInput
///
/// Properties:
/// * [playerId] 
/// * [testTypeId] 
/// * [measuredOn] 
/// * [value] - In the test type's unit.
/// * [notes] 
@BuiltValue()
abstract class PhysicalTestResultInput implements Built<PhysicalTestResultInput, PhysicalTestResultInputBuilder> {
  @BuiltValueField(wireName: r'playerId')
  String get playerId;

  @BuiltValueField(wireName: r'testTypeId')
  String get testTypeId;

  @BuiltValueField(wireName: r'measuredOn')
  Date get measuredOn;

  /// In the test type's unit.
  @BuiltValueField(wireName: r'value')
  double get value;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  PhysicalTestResultInput._();

  factory PhysicalTestResultInput([void updates(PhysicalTestResultInputBuilder b)]) = _$PhysicalTestResultInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhysicalTestResultInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhysicalTestResultInput> get serializer => _$PhysicalTestResultInputSerializer();
}

class _$PhysicalTestResultInputSerializer implements PrimitiveSerializer<PhysicalTestResultInput> {
  @override
  final Iterable<Type> types = const [PhysicalTestResultInput, _$PhysicalTestResultInput];

  @override
  final String wireName = r'PhysicalTestResultInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhysicalTestResultInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'playerId';
    yield serializers.serialize(
      object.playerId,
      specifiedType: const FullType(String),
    );
    yield r'testTypeId';
    yield serializers.serialize(
      object.testTypeId,
      specifiedType: const FullType(String),
    );
    yield r'measuredOn';
    yield serializers.serialize(
      object.measuredOn,
      specifiedType: const FullType(Date),
    );
    yield r'value';
    yield serializers.serialize(
      object.value,
      specifiedType: const FullType(double),
    );
    if (object.notes != null) {
      yield r'notes';
      yield serializers.serialize(
        object.notes,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PhysicalTestResultInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhysicalTestResultInputBuilder result,
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
        case r'testTypeId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.testTypeId = valueDes;
          break;
        case r'measuredOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.measuredOn = valueDes;
          break;
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.value = valueDes;
          break;
        case r'notes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.notes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhysicalTestResultInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhysicalTestResultInputBuilder();
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


