//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/plan_item_ref.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'copy_plan_items_request.g.dart';

/// CopyPlanItemsRequest
///
/// Properties:
/// * [items] - Items to copy, in this order; the same item may be given twice (two copies).
@BuiltValue()
abstract class CopyPlanItemsRequest implements Built<CopyPlanItemsRequest, CopyPlanItemsRequestBuilder> {
  /// Items to copy, in this order; the same item may be given twice (two copies).
  @BuiltValueField(wireName: r'items')
  BuiltList<PlanItemRef> get items;

  CopyPlanItemsRequest._();

  factory CopyPlanItemsRequest([void updates(CopyPlanItemsRequestBuilder b)]) = _$CopyPlanItemsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CopyPlanItemsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CopyPlanItemsRequest> get serializer => _$CopyPlanItemsRequestSerializer();
}

class _$CopyPlanItemsRequestSerializer implements PrimitiveSerializer<CopyPlanItemsRequest> {
  @override
  final Iterable<Type> types = const [CopyPlanItemsRequest, _$CopyPlanItemsRequest];

  @override
  final String wireName = r'CopyPlanItemsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CopyPlanItemsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(PlanItemRef)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CopyPlanItemsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CopyPlanItemsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlanItemRef)]),
          ) as BuiltList<PlanItemRef>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CopyPlanItemsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CopyPlanItemsRequestBuilder();
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


