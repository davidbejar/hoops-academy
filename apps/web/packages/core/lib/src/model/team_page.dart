//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:hoops_core_api/src/model/team.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_page.g.dart';

/// TeamPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class TeamPage implements Built<TeamPage, TeamPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Team> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  TeamPage._();

  factory TeamPage([void updates(TeamPageBuilder b)]) = _$TeamPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TeamPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TeamPage> get serializer => _$TeamPageSerializer();
}

class _$TeamPageSerializer implements PrimitiveSerializer<TeamPage> {
  @override
  final Iterable<Type> types = const [TeamPage, _$TeamPage];

  @override
  final String wireName = r'TeamPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TeamPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Team)]),
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
    TeamPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TeamPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Team)]),
          ) as BuiltList<Team>;
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
  TeamPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TeamPageBuilder();
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


