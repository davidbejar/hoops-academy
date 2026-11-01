//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:hoops_athlete_api/src/model/plan_assignment.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_assignment_page.g.dart';

/// PlanAssignmentPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class PlanAssignmentPage implements Built<PlanAssignmentPage, PlanAssignmentPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<PlanAssignment> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  PlanAssignmentPage._();

  factory PlanAssignmentPage([void updates(PlanAssignmentPageBuilder b)]) = _$PlanAssignmentPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanAssignmentPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanAssignmentPage> get serializer => _$PlanAssignmentPageSerializer();
}

class _$PlanAssignmentPageSerializer implements PrimitiveSerializer<PlanAssignmentPage> {
  @override
  final Iterable<Type> types = const [PlanAssignmentPage, _$PlanAssignmentPage];

  @override
  final String wireName = r'PlanAssignmentPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanAssignmentPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(PlanAssignment)]),
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
    PlanAssignmentPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanAssignmentPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlanAssignment)]),
          ) as BuiltList<PlanAssignment>;
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
  PlanAssignmentPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanAssignmentPageBuilder();
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


