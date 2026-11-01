//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:hoops_athlete_api/src/model/plan_completion.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_completion_page.g.dart';

/// PlanCompletionPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class PlanCompletionPage implements Built<PlanCompletionPage, PlanCompletionPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<PlanCompletion> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  PlanCompletionPage._();

  factory PlanCompletionPage([void updates(PlanCompletionPageBuilder b)]) = _$PlanCompletionPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanCompletionPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanCompletionPage> get serializer => _$PlanCompletionPageSerializer();
}

class _$PlanCompletionPageSerializer implements PrimitiveSerializer<PlanCompletionPage> {
  @override
  final Iterable<Type> types = const [PlanCompletionPage, _$PlanCompletionPage];

  @override
  final String wireName = r'PlanCompletionPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanCompletionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(PlanCompletion)]),
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
    PlanCompletionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanCompletionPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlanCompletion)]),
          ) as BuiltList<PlanCompletion>;
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
  PlanCompletionPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanCompletionPageBuilder();
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


