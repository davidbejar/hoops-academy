//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/audit_event.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_event_page.g.dart';

/// AuditEventPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class AuditEventPage implements Built<AuditEventPage, AuditEventPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<AuditEvent> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  AuditEventPage._();

  factory AuditEventPage([void updates(AuditEventPageBuilder b)]) = _$AuditEventPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuditEventPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuditEventPage> get serializer => _$AuditEventPageSerializer();
}

class _$AuditEventPageSerializer implements PrimitiveSerializer<AuditEventPage> {
  @override
  final Iterable<Type> types = const [AuditEventPage, _$AuditEventPage];

  @override
  final String wireName = r'AuditEventPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuditEventPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(AuditEvent)]),
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
    AuditEventPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuditEventPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AuditEvent)]),
          ) as BuiltList<AuditEvent>;
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
  AuditEventPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuditEventPageBuilder();
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


