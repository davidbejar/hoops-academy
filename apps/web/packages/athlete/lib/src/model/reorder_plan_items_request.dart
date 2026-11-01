//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reorder_plan_items_request.g.dart';

/// ReorderPlanItemsRequest
///
/// Properties:
/// * [itemIds] 
@BuiltValue()
abstract class ReorderPlanItemsRequest implements Built<ReorderPlanItemsRequest, ReorderPlanItemsRequestBuilder> {
  @BuiltValueField(wireName: r'itemIds')
  BuiltSet<String> get itemIds;

  ReorderPlanItemsRequest._();

  factory ReorderPlanItemsRequest([void updates(ReorderPlanItemsRequestBuilder b)]) = _$ReorderPlanItemsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReorderPlanItemsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReorderPlanItemsRequest> get serializer => _$ReorderPlanItemsRequestSerializer();
}

class _$ReorderPlanItemsRequestSerializer implements PrimitiveSerializer<ReorderPlanItemsRequest> {
  @override
  final Iterable<Type> types = const [ReorderPlanItemsRequest, _$ReorderPlanItemsRequest];

  @override
  final String wireName = r'ReorderPlanItemsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReorderPlanItemsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'itemIds';
    yield serializers.serialize(
      object.itemIds,
      specifiedType: const FullType(BuiltSet, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReorderPlanItemsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReorderPlanItemsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'itemIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltSet, [FullType(String)]),
          ) as BuiltSet<String>;
          result.itemIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReorderPlanItemsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReorderPlanItemsRequestBuilder();
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


