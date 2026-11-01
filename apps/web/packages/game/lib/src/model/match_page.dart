//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_game_api/src/model/match.dart';
import 'package:hoops_game_api/src/model/page_meta.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_page.g.dart';

/// MatchPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class MatchPage implements Built<MatchPage, MatchPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Match> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  MatchPage._();

  factory MatchPage([void updates(MatchPageBuilder b)]) = _$MatchPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchPage> get serializer => _$MatchPageSerializer();
}

class _$MatchPageSerializer implements PrimitiveSerializer<MatchPage> {
  @override
  final Iterable<Type> types = const [MatchPage, _$MatchPage];

  @override
  final String wireName = r'MatchPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Match)]),
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
    MatchPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Match)]),
          ) as BuiltList<Match>;
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
  MatchPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchPageBuilder();
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


