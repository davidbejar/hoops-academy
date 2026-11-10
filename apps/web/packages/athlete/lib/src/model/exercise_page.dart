//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/exercise.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'exercise_page.g.dart';

/// ExercisePage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class ExercisePage implements Built<ExercisePage, ExercisePageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Exercise> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  ExercisePage._();

  factory ExercisePage([void updates(ExercisePageBuilder b)]) = _$ExercisePage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExercisePageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExercisePage> get serializer => _$ExercisePageSerializer();
}

class _$ExercisePageSerializer implements PrimitiveSerializer<ExercisePage> {
  @override
  final Iterable<Type> types = const [ExercisePage, _$ExercisePage];

  @override
  final String wireName = r'ExercisePage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExercisePage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Exercise)]),
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
    ExercisePage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExercisePageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Exercise)]),
          ) as BuiltList<Exercise>;
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
  ExercisePage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExercisePageBuilder();
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


