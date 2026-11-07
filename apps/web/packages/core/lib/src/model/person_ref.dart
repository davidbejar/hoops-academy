//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'person_ref.g.dart';

/// Minimal reference to a person (member) for audit fields.
///
/// Properties:
/// * [personId]
/// * [displayName]
@BuiltValue()
abstract class PersonRef implements Built<PersonRef, PersonRefBuilder> {
  @BuiltValueField(wireName: r'personId')
  String get personId;

  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  PersonRef._();

  factory PersonRef([void updates(PersonRefBuilder b)]) = _$PersonRef;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PersonRefBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PersonRef> get serializer => _$PersonRefSerializer();
}

class _$PersonRefSerializer implements PrimitiveSerializer<PersonRef> {
  @override
  final Iterable<Type> types = const [PersonRef, _$PersonRef];

  @override
  final String wireName = r'PersonRef';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PersonRef object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'personId';
    yield serializers.serialize(
      object.personId,
      specifiedType: const FullType(String),
    );
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PersonRef object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PersonRefBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'personId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.personId = valueDes;
          break;
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PersonRef deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PersonRefBuilder();
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
