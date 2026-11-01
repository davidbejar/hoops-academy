//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'copy_training_plan_request.g.dart';

/// CopyTrainingPlanRequest
///
/// Properties:
/// * [name] - Defaults to the source plan's name.
@BuiltValue()
abstract class CopyTrainingPlanRequest implements Built<CopyTrainingPlanRequest, CopyTrainingPlanRequestBuilder> {
  /// Defaults to the source plan's name.
  @BuiltValueField(wireName: r'name')
  String? get name;

  CopyTrainingPlanRequest._();

  factory CopyTrainingPlanRequest([void updates(CopyTrainingPlanRequestBuilder b)]) = _$CopyTrainingPlanRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CopyTrainingPlanRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CopyTrainingPlanRequest> get serializer => _$CopyTrainingPlanRequestSerializer();
}

class _$CopyTrainingPlanRequestSerializer implements PrimitiveSerializer<CopyTrainingPlanRequest> {
  @override
  final Iterable<Type> types = const [CopyTrainingPlanRequest, _$CopyTrainingPlanRequest];

  @override
  final String wireName = r'CopyTrainingPlanRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CopyTrainingPlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CopyTrainingPlanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CopyTrainingPlanRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CopyTrainingPlanRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CopyTrainingPlanRequestBuilder();
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


