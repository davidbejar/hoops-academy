//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'problem_violation.g.dart';

/// ProblemViolation
///
/// Properties:
/// * [field] - Dotted path of the offending field, when applicable.
/// * [code] - Machine-readable reason, e.g. `MISSING_BIRTH_DATE`.
/// * [message] 
@BuiltValue()
abstract class ProblemViolation implements Built<ProblemViolation, ProblemViolationBuilder> {
  /// Dotted path of the offending field, when applicable.
  @BuiltValueField(wireName: r'field')
  String? get field;

  /// Machine-readable reason, e.g. `MISSING_BIRTH_DATE`.
  @BuiltValueField(wireName: r'code')
  String? get code;

  @BuiltValueField(wireName: r'message')
  String get message;

  ProblemViolation._();

  factory ProblemViolation([void updates(ProblemViolationBuilder b)]) = _$ProblemViolation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProblemViolationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProblemViolation> get serializer => _$ProblemViolationSerializer();
}

class _$ProblemViolationSerializer implements PrimitiveSerializer<ProblemViolation> {
  @override
  final Iterable<Type> types = const [ProblemViolation, _$ProblemViolation];

  @override
  final String wireName = r'ProblemViolation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProblemViolation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.field != null) {
      yield r'field';
      yield serializers.serialize(
        object.field,
        specifiedType: const FullType(String),
      );
    }
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType(String),
      );
    }
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProblemViolation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProblemViolationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'field':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.field = valueDes;
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.code = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProblemViolation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProblemViolationBuilder();
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


