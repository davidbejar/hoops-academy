//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_athlete_api/src/model/injury.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'injury_page.g.dart';

/// InjuryPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class InjuryPage implements Built<InjuryPage, InjuryPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Injury> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  InjuryPage._();

  factory InjuryPage([void updates(InjuryPageBuilder b)]) = _$InjuryPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InjuryPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InjuryPage> get serializer => _$InjuryPageSerializer();
}

class _$InjuryPageSerializer implements PrimitiveSerializer<InjuryPage> {
  @override
  final Iterable<Type> types = const [InjuryPage, _$InjuryPage];

  @override
  final String wireName = r'InjuryPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InjuryPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Injury)]),
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
    InjuryPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required InjuryPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Injury)]),
          ) as BuiltList<Injury>;
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
  InjuryPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InjuryPageBuilder();
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


