//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'generate_dues_request.g.dart';

/// GenerateDuesRequest
///
/// Properties:
/// * [period] - A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
/// * [preview] - true = compute and return, write nothing.
@BuiltValue()
abstract class GenerateDuesRequest implements Built<GenerateDuesRequest, GenerateDuesRequestBuilder> {
  /// A calendar month `YYYY-MM`, a calendar quarter `YYYY-Qn`, or `SEASON` (the plan's cadence decides).
  @BuiltValueField(wireName: r'period')
  String get period;

  /// true = compute and return, write nothing.
  @BuiltValueField(wireName: r'preview')
  bool? get preview;

  GenerateDuesRequest._();

  factory GenerateDuesRequest([void updates(GenerateDuesRequestBuilder b)]) = _$GenerateDuesRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GenerateDuesRequestBuilder b) => b
      ..preview = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<GenerateDuesRequest> get serializer => _$GenerateDuesRequestSerializer();
}

class _$GenerateDuesRequestSerializer implements PrimitiveSerializer<GenerateDuesRequest> {
  @override
  final Iterable<Type> types = const [GenerateDuesRequest, _$GenerateDuesRequest];

  @override
  final String wireName = r'GenerateDuesRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GenerateDuesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(String),
    );
    if (object.preview != null) {
      yield r'preview';
      yield serializers.serialize(
        object.preview,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    GenerateDuesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GenerateDuesRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'period':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.period = valueDes;
          break;
        case r'preview':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.preview = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GenerateDuesRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GenerateDuesRequestBuilder();
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
