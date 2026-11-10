//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_item_source.g.dart';

/// What one quick-added item is copied from (3.0.0, replaces `PlanItemRef`): either `exerciseId` alone (a catalogue exercise the academy reads, not archived) or `planId` + `itemId` (an item of any readable plan or template). Any other combination is 400. 
///
/// Properties:
/// * [exerciseId] - A global exercise or one of the academy's own.
/// * [planId] - Any plan the academy can read (a tenant plan or a global template); with `itemId`.
/// * [itemId] - An item of `planId`.
@BuiltValue()
abstract class PlanItemSource implements Built<PlanItemSource, PlanItemSourceBuilder> {
  /// A global exercise or one of the academy's own.
  @BuiltValueField(wireName: r'exerciseId')
  String? get exerciseId;

  /// Any plan the academy can read (a tenant plan or a global template); with `itemId`.
  @BuiltValueField(wireName: r'planId')
  String? get planId;

  /// An item of `planId`.
  @BuiltValueField(wireName: r'itemId')
  String? get itemId;

  PlanItemSource._();

  factory PlanItemSource([void updates(PlanItemSourceBuilder b)]) = _$PlanItemSource;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanItemSourceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanItemSource> get serializer => _$PlanItemSourceSerializer();
}

class _$PlanItemSourceSerializer implements PrimitiveSerializer<PlanItemSource> {
  @override
  final Iterable<Type> types = const [PlanItemSource, _$PlanItemSource];

  @override
  final String wireName = r'PlanItemSource';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanItemSource object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.exerciseId != null) {
      yield r'exerciseId';
      yield serializers.serialize(
        object.exerciseId,
        specifiedType: const FullType(String),
      );
    }
    if (object.planId != null) {
      yield r'planId';
      yield serializers.serialize(
        object.planId,
        specifiedType: const FullType(String),
      );
    }
    if (object.itemId != null) {
      yield r'itemId';
      yield serializers.serialize(
        object.itemId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanItemSource object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanItemSourceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'exerciseId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.exerciseId = valueDes;
          break;
        case r'planId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.planId = valueDes;
          break;
        case r'itemId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  PlanItemSource deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanItemSourceBuilder();
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


