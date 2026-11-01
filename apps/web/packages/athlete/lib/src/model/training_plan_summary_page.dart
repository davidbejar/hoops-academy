//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:hoops_athlete_api/src/model/training_plan_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'training_plan_summary_page.g.dart';

/// TrainingPlanSummaryPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class TrainingPlanSummaryPage implements Built<TrainingPlanSummaryPage, TrainingPlanSummaryPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<TrainingPlanSummary> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  TrainingPlanSummaryPage._();

  factory TrainingPlanSummaryPage([void updates(TrainingPlanSummaryPageBuilder b)]) = _$TrainingPlanSummaryPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrainingPlanSummaryPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrainingPlanSummaryPage> get serializer => _$TrainingPlanSummaryPageSerializer();
}

class _$TrainingPlanSummaryPageSerializer implements PrimitiveSerializer<TrainingPlanSummaryPage> {
  @override
  final Iterable<Type> types = const [TrainingPlanSummaryPage, _$TrainingPlanSummaryPage];

  @override
  final String wireName = r'TrainingPlanSummaryPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrainingPlanSummaryPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(TrainingPlanSummary)]),
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
    TrainingPlanSummaryPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrainingPlanSummaryPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TrainingPlanSummary)]),
          ) as BuiltList<TrainingPlanSummary>;
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
  TrainingPlanSummaryPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrainingPlanSummaryPageBuilder();
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


