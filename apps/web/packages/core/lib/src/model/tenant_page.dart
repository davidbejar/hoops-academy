//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/tenant.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_page.g.dart';

/// TenantPage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class TenantPage implements Built<TenantPage, TenantPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Tenant> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  TenantPage._();

  factory TenantPage([void updates(TenantPageBuilder b)]) = _$TenantPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantPage> get serializer => _$TenantPageSerializer();
}

class _$TenantPageSerializer implements PrimitiveSerializer<TenantPage> {
  @override
  final Iterable<Type> types = const [TenantPage, _$TenantPage];

  @override
  final String wireName = r'TenantPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Tenant)]),
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
    TenantPage object, {
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
    required TenantPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Tenant)]),
          ) as BuiltList<Tenant>;
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
  TenantPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantPageBuilder();
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
