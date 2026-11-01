//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'note_payload.g.dart';

/// NotePayload
///
/// Properties:
/// * [text] 
@BuiltValue()
abstract class NotePayload implements Built<NotePayload, NotePayloadBuilder> {
  @BuiltValueField(wireName: r'text')
  String get text;

  NotePayload._();

  factory NotePayload([void updates(NotePayloadBuilder b)]) = _$NotePayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotePayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotePayload> get serializer => _$NotePayloadSerializer();
}

class _$NotePayloadSerializer implements PrimitiveSerializer<NotePayload> {
  @override
  final Iterable<Type> types = const [NotePayload, _$NotePayload];

  @override
  final String wireName = r'NotePayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotePayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotePayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotePayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotePayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotePayloadBuilder();
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


