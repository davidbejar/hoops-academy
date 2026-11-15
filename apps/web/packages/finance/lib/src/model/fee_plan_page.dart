//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_finance_api/src/model/fee_plan.dart';
import 'package:hoops_finance_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fee_plan_page.g.dart';

/// FeePlanPage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class FeePlanPage implements Built<FeePlanPage, FeePlanPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<FeePlan> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  FeePlanPage._();

  factory FeePlanPage([void updates(FeePlanPageBuilder b)]) = _$FeePlanPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FeePlanPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FeePlanPage> get serializer => _$FeePlanPageSerializer();
}

class _$FeePlanPageSerializer implements PrimitiveSerializer<FeePlanPage> {
  @override
  final Iterable<Type> types = const [FeePlanPage, _$FeePlanPage];

  @override
  final String wireName = r'FeePlanPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FeePlanPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(FeePlan)]),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(PageMeta),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FeePlanPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FeePlanPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FeePlan)]),
          ) as BuiltList<FeePlan>;
          result.items.replace(valueDes);
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PageMeta),
          ) as PageMeta;
          result.page.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FeePlanPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FeePlanPageBuilder();
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
