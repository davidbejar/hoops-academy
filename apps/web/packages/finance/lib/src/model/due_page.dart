//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/due.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_finance_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'due_page.g.dart';

/// DuePage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class DuePage implements Built<DuePage, DuePageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Due> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  DuePage._();

  factory DuePage([void updates(DuePageBuilder b)]) = _$DuePage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DuePageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DuePage> get serializer => _$DuePageSerializer();
}

class _$DuePageSerializer implements PrimitiveSerializer<DuePage> {
  @override
  final Iterable<Type> types = const [DuePage, _$DuePage];

  @override
  final String wireName = r'DuePage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DuePage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Due)]),
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
    DuePage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DuePageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Due)]),
          ) as BuiltList<Due>;
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
  DuePage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DuePageBuilder();
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
