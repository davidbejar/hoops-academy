//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_physical_test_result_request.g.dart';

/// UpdatePhysicalTestResultRequest
///
/// Properties:
/// * [measuredOn]
/// * [value]
/// * [notes]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdatePhysicalTestResultRequest implements Built<UpdatePhysicalTestResultRequest, UpdatePhysicalTestResultRequestBuilder> {
  @BuiltValueField(wireName: r'measuredOn')
  Date? get measuredOn;

  @BuiltValueField(wireName: r'value')
  double? get value;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdatePhysicalTestResultRequestClearEnum>? get clear;
  // enum clearEnum {  notes,  };

  UpdatePhysicalTestResultRequest._();

  factory UpdatePhysicalTestResultRequest([void updates(UpdatePhysicalTestResultRequestBuilder b)]) = _$UpdatePhysicalTestResultRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePhysicalTestResultRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePhysicalTestResultRequest> get serializer => _$UpdatePhysicalTestResultRequestSerializer();
}

class _$UpdatePhysicalTestResultRequestSerializer implements PrimitiveSerializer<UpdatePhysicalTestResultRequest> {
  @override
  final Iterable<Type> types = const [UpdatePhysicalTestResultRequest, _$UpdatePhysicalTestResultRequest];

  @override
  final String wireName = r'UpdatePhysicalTestResultRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePhysicalTestResultRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.measuredOn != null) {
      yield r'measuredOn';
      yield serializers.serialize(
        object.measuredOn,
        specifiedType: const FullType(Date),
      );
    }
    if (object.value != null) {
      yield r'value';
      yield serializers.serialize(
        object.value,
        specifiedType: const FullType(double),
      );
    }
    if (object.notes != null) {
      yield r'notes';
      yield serializers.serialize(
        object.notes,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdatePhysicalTestResultRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePhysicalTestResultRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePhysicalTestResultRequestBuilder result,
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
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
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
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdatePhysicalTestResultRequestClearEnum)]),
          ) as BuiltSet<UpdatePhysicalTestResultRequestClearEnum>?;
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
  UpdatePhysicalTestResultRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePhysicalTestResultRequestBuilder();
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


class UpdatePhysicalTestResultRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'notes')
  static const UpdatePhysicalTestResultRequestClearEnum notes = _$updatePhysicalTestResultRequestClearEnum_notes;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdatePhysicalTestResultRequestClearEnum unknownDefaultOpenApi = _$updatePhysicalTestResultRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdatePhysicalTestResultRequestClearEnum> get serializer => _$updatePhysicalTestResultRequestClearEnumSerializer;

  const UpdatePhysicalTestResultRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdatePhysicalTestResultRequestClearEnum> get values => _$updatePhysicalTestResultRequestClearEnumValues;
  static UpdatePhysicalTestResultRequestClearEnum valueOf(String name) => _$updatePhysicalTestResultRequestClearEnumValueOf(name);
}
