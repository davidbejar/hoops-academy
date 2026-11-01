//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/planned_absence.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'planned_absence_page.g.dart';

/// PlannedAbsencePage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class PlannedAbsencePage implements Built<PlannedAbsencePage, PlannedAbsencePageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<PlannedAbsence> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  PlannedAbsencePage._();

  factory PlannedAbsencePage([void updates(PlannedAbsencePageBuilder b)]) = _$PlannedAbsencePage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlannedAbsencePageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlannedAbsencePage> get serializer => _$PlannedAbsencePageSerializer();
}

class _$PlannedAbsencePageSerializer implements PrimitiveSerializer<PlannedAbsencePage> {
  @override
  final Iterable<Type> types = const [PlannedAbsencePage, _$PlannedAbsencePage];

  @override
  final String wireName = r'PlannedAbsencePage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlannedAbsencePage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(PlannedAbsence)]),
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
    PlannedAbsencePage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlannedAbsencePageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlannedAbsence)]),
          ) as BuiltList<PlannedAbsence>;
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
  PlannedAbsencePage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlannedAbsencePageBuilder();
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


