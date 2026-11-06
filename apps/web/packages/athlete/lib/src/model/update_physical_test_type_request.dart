//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_physical_test_type_request.g.dart';

/// UpdatePhysicalTestTypeRequest
///
/// Properties:
/// * [code] - Unique across global and tenant types (409); results show the new code.
/// * [name]
/// * [unit]
/// * [higherIsBetter]
/// * [description]
/// * [clear] - Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
@BuiltValue()
abstract class UpdatePhysicalTestTypeRequest implements Built<UpdatePhysicalTestTypeRequest, UpdatePhysicalTestTypeRequestBuilder> {
  /// Unique across global and tenant types (409); results show the new code.
  @BuiltValueField(wireName: r'code')
  String? get code;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'unit')
  String? get unit;

  @BuiltValueField(wireName: r'higherIsBetter')
  bool? get higherIsBetter;

  @BuiltValueField(wireName: r'description')
  String? get description;

  /// Properties to set to null (ADR-0032). An absent or null property stays unchanged; a property named here must not also be given a value (400).
  @BuiltValueField(wireName: r'clear')
  BuiltSet<UpdatePhysicalTestTypeRequestClearEnum>? get clear;
  // enum clearEnum {  description,  };

  UpdatePhysicalTestTypeRequest._();

  factory UpdatePhysicalTestTypeRequest([void updates(UpdatePhysicalTestTypeRequestBuilder b)]) = _$UpdatePhysicalTestTypeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePhysicalTestTypeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePhysicalTestTypeRequest> get serializer => _$UpdatePhysicalTestTypeRequestSerializer();
}

class _$UpdatePhysicalTestTypeRequestSerializer implements PrimitiveSerializer<UpdatePhysicalTestTypeRequest> {
  @override
  final Iterable<Type> types = const [UpdatePhysicalTestTypeRequest, _$UpdatePhysicalTestTypeRequest];

  @override
  final String wireName = r'UpdatePhysicalTestTypeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePhysicalTestTypeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType(String),
      );
    }
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.unit != null) {
      yield r'unit';
      yield serializers.serialize(
        object.unit,
        specifiedType: const FullType(String),
      );
    }
    if (object.higherIsBetter != null) {
      yield r'higherIsBetter';
      yield serializers.serialize(
        object.higherIsBetter,
        specifiedType: const FullType(bool),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.clear != null) {
      yield r'clear';
      yield serializers.serialize(
        object.clear,
        specifiedType: const FullType(BuiltSet, [FullType(UpdatePhysicalTestTypeRequestClearEnum)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePhysicalTestTypeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePhysicalTestTypeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.code = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'unit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.unit = valueDes;
          break;
        case r'higherIsBetter':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.higherIsBetter = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'clear':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltSet, [FullType(UpdatePhysicalTestTypeRequestClearEnum)]),
          ) as BuiltSet<UpdatePhysicalTestTypeRequestClearEnum>?;
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
  UpdatePhysicalTestTypeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePhysicalTestTypeRequestBuilder();
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


class UpdatePhysicalTestTypeRequestClearEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'description')
  static const UpdatePhysicalTestTypeRequestClearEnum description = _$updatePhysicalTestTypeRequestClearEnum_description;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UpdatePhysicalTestTypeRequestClearEnum unknownDefaultOpenApi = _$updatePhysicalTestTypeRequestClearEnum_unknownDefaultOpenApi;

  static Serializer<UpdatePhysicalTestTypeRequestClearEnum> get serializer => _$updatePhysicalTestTypeRequestClearEnumSerializer;

  const UpdatePhysicalTestTypeRequestClearEnum._(String name): super(name);

  static BuiltSet<UpdatePhysicalTestTypeRequestClearEnum> get values => _$updatePhysicalTestTypeRequestClearEnumValues;
  static UpdatePhysicalTestTypeRequestClearEnum valueOf(String name) => _$updatePhysicalTestTypeRequestClearEnumValueOf(name);
}
