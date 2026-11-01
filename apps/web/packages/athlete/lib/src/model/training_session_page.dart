//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:hoops_athlete_api/src/model/training_session.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'training_session_page.g.dart';

/// TrainingSessionPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class TrainingSessionPage implements Built<TrainingSessionPage, TrainingSessionPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<TrainingSession> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  TrainingSessionPage._();

  factory TrainingSessionPage([void updates(TrainingSessionPageBuilder b)]) = _$TrainingSessionPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrainingSessionPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrainingSessionPage> get serializer => _$TrainingSessionPageSerializer();
}

class _$TrainingSessionPageSerializer implements PrimitiveSerializer<TrainingSessionPage> {
  @override
  final Iterable<Type> types = const [TrainingSessionPage, _$TrainingSessionPage];

  @override
  final String wireName = r'TrainingSessionPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrainingSessionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(TrainingSession)]),
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
    TrainingSessionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrainingSessionPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TrainingSession)]),
          ) as BuiltList<TrainingSession>;
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
  TrainingSessionPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrainingSessionPageBuilder();
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


