//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/guardian_link.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'guardian_link_page.g.dart';

/// GuardianLinkPage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class GuardianLinkPage
    implements Built<GuardianLinkPage, GuardianLinkPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<GuardianLink> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  GuardianLinkPage._();

  factory GuardianLinkPage([void updates(GuardianLinkPageBuilder b)]) =
      _$GuardianLinkPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GuardianLinkPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GuardianLinkPage> get serializer =>
      _$GuardianLinkPageSerializer();
}

class _$GuardianLinkPageSerializer
    implements PrimitiveSerializer<GuardianLinkPage> {
  @override
  final Iterable<Type> types = const [GuardianLinkPage, _$GuardianLinkPage];

  @override
  final String wireName = r'GuardianLinkPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GuardianLinkPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(GuardianLink)]),
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
    GuardianLinkPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GuardianLinkPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GuardianLink)]),
          ) as BuiltList<GuardianLink>;
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
  GuardianLinkPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GuardianLinkPageBuilder();
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
