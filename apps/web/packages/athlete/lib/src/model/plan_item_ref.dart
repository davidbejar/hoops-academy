//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_item_ref.g.dart';

/// PlanItemRef
///
/// Properties:
/// * [planId] - Any plan the academy can read (a tenant plan or a global template).
/// * [itemId] 
@BuiltValue()
abstract class PlanItemRef implements Built<PlanItemRef, PlanItemRefBuilder> {
  /// Any plan the academy can read (a tenant plan or a global template).
  @BuiltValueField(wireName: r'planId')
  String get planId;

  @BuiltValueField(wireName: r'itemId')
  String get itemId;

  PlanItemRef._();

  factory PlanItemRef([void updates(PlanItemRefBuilder b)]) = _$PlanItemRef;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanItemRefBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanItemRef> get serializer => _$PlanItemRefSerializer();
}

class _$PlanItemRefSerializer implements PrimitiveSerializer<PlanItemRef> {
  @override
  final Iterable<Type> types = const [PlanItemRef, _$PlanItemRef];

  @override
  final String wireName = r'PlanItemRef';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanItemRef object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'planId';
    yield serializers.serialize(
      object.planId,
      specifiedType: const FullType(String),
    );
    yield r'itemId';
    yield serializers.serialize(
      object.itemId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanItemRef object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanItemRefBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'planId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.planId = valueDes;
          break;
        case r'itemId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.itemId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanItemRef deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanItemRefBuilder();
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


