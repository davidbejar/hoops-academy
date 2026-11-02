//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:hoops_core_api/src/model/tenant_admin.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_admin_page.g.dart';

/// TenantAdminPage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class TenantAdminPage implements Built<TenantAdminPage, TenantAdminPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<TenantAdmin> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  TenantAdminPage._();

  factory TenantAdminPage([void updates(TenantAdminPageBuilder b)]) = _$TenantAdminPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TenantAdminPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TenantAdminPage> get serializer => _$TenantAdminPageSerializer();
}

class _$TenantAdminPageSerializer implements PrimitiveSerializer<TenantAdminPage> {
  @override
  final Iterable<Type> types = const [TenantAdminPage, _$TenantAdminPage];

  @override
  final String wireName = r'TenantAdminPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TenantAdminPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(TenantAdmin)]),
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
    TenantAdminPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TenantAdminPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TenantAdmin)]),
          ) as BuiltList<TenantAdmin>;
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
  TenantAdminPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TenantAdminPageBuilder();
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
