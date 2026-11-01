//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_progress_counts.g.dart';

/// PlanProgressCounts
///
/// Properties:
/// * [DONE] 
/// * [PARTIAL] 
/// * [NOT_DONE] 
@BuiltValue()
abstract class PlanProgressCounts implements Built<PlanProgressCounts, PlanProgressCountsBuilder> {
  @BuiltValueField(wireName: r'DONE')
  int get DONE;

  @BuiltValueField(wireName: r'PARTIAL')
  int get PARTIAL;

  @BuiltValueField(wireName: r'NOT_DONE')
  int get NOT_DONE;

  PlanProgressCounts._();

  factory PlanProgressCounts([void updates(PlanProgressCountsBuilder b)]) = _$PlanProgressCounts;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanProgressCountsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanProgressCounts> get serializer => _$PlanProgressCountsSerializer();
}

class _$PlanProgressCountsSerializer implements PrimitiveSerializer<PlanProgressCounts> {
  @override
  final Iterable<Type> types = const [PlanProgressCounts, _$PlanProgressCounts];

  @override
  final String wireName = r'PlanProgressCounts';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanProgressCounts object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'DONE';
    yield serializers.serialize(
      object.DONE,
      specifiedType: const FullType(int),
    );
    yield r'PARTIAL';
    yield serializers.serialize(
      object.PARTIAL,
      specifiedType: const FullType(int),
    );
    yield r'NOT_DONE';
    yield serializers.serialize(
      object.NOT_DONE,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanProgressCounts object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanProgressCountsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'DONE':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.DONE = valueDes;
          break;
        case r'PARTIAL':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.PARTIAL = valueDes;
          break;
        case r'NOT_DONE':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.NOT_DONE = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanProgressCounts deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanProgressCountsBuilder();
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


