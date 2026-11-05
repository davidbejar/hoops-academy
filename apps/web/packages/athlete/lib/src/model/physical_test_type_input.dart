//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'physical_test_type_input.g.dart';

/// PhysicalTestTypeInput
///
/// Properties:
/// * [code]
/// * [name]
/// * [unit]
/// * [higherIsBetter]
/// * [description]
@BuiltValue()
abstract class PhysicalTestTypeInput implements Built<PhysicalTestTypeInput, PhysicalTestTypeInputBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'unit')
  String get unit;

  @BuiltValueField(wireName: r'higherIsBetter')
  bool get higherIsBetter;

  @BuiltValueField(wireName: r'description')
  String? get description;

  PhysicalTestTypeInput._();

  factory PhysicalTestTypeInput([void updates(PhysicalTestTypeInputBuilder b)]) = _$PhysicalTestTypeInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhysicalTestTypeInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhysicalTestTypeInput> get serializer => _$PhysicalTestTypeInputSerializer();
}

class _$PhysicalTestTypeInputSerializer implements PrimitiveSerializer<PhysicalTestTypeInput> {
  @override
  final Iterable<Type> types = const [PhysicalTestTypeInput, _$PhysicalTestTypeInput];

  @override
  final String wireName = r'PhysicalTestTypeInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhysicalTestTypeInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'unit';
    yield serializers.serialize(
      object.unit,
      specifiedType: const FullType(String),
    );
    yield r'higherIsBetter';
    yield serializers.serialize(
      object.higherIsBetter,
      specifiedType: const FullType(bool),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PhysicalTestTypeInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhysicalTestTypeInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'unit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.unit = valueDes;
          break;
        case r'higherIsBetter':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhysicalTestTypeInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhysicalTestTypeInputBuilder();
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
