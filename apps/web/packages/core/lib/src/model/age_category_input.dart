//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'age_category_input.g.dart';

/// AgeCategoryInput
///
/// Properties:
/// * [code] 
/// * [name] 
/// * [maxAge] - Inclusive maximum age; null = senior (no limit).
/// * [rank] - Ordering; higher rank = older category.
@BuiltValue()
abstract class AgeCategoryInput implements Built<AgeCategoryInput, AgeCategoryInputBuilder> {
  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'name')
  String get name;

  /// Inclusive maximum age; null = senior (no limit).
  @BuiltValueField(wireName: r'maxAge')
  int? get maxAge;

  /// Ordering; higher rank = older category.
  @BuiltValueField(wireName: r'rank')
  int get rank;

  AgeCategoryInput._();

  factory AgeCategoryInput([void updates(AgeCategoryInputBuilder b)]) = _$AgeCategoryInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AgeCategoryInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AgeCategoryInput> get serializer => _$AgeCategoryInputSerializer();
}

class _$AgeCategoryInputSerializer implements PrimitiveSerializer<AgeCategoryInput> {
  @override
  final Iterable<Type> types = const [AgeCategoryInput, _$AgeCategoryInput];

  @override
  final String wireName = r'AgeCategoryInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AgeCategoryInput object, {
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
    if (object.maxAge != null) {
      yield r'maxAge';
      yield serializers.serialize(
        object.maxAge,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'rank';
    yield serializers.serialize(
      object.rank,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AgeCategoryInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AgeCategoryInputBuilder result,
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
        case r'maxAge':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.maxAge = valueDes;
          break;
        case r'rank':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.rank = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AgeCategoryInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AgeCategoryInputBuilder();
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


