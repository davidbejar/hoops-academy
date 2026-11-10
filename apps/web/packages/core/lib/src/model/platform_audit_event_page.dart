//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:hoops_core_api/src/model/platform_audit_event.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'platform_audit_event_page.g.dart';

/// PlatformAuditEventPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class PlatformAuditEventPage implements Built<PlatformAuditEventPage, PlatformAuditEventPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<PlatformAuditEvent> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  PlatformAuditEventPage._();

  factory PlatformAuditEventPage([void updates(PlatformAuditEventPageBuilder b)]) = _$PlatformAuditEventPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlatformAuditEventPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlatformAuditEventPage> get serializer => _$PlatformAuditEventPageSerializer();
}

class _$PlatformAuditEventPageSerializer implements PrimitiveSerializer<PlatformAuditEventPage> {
  @override
  final Iterable<Type> types = const [PlatformAuditEventPage, _$PlatformAuditEventPage];

  @override
  final String wireName = r'PlatformAuditEventPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlatformAuditEventPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(PlatformAuditEvent)]),
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
    PlatformAuditEventPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlatformAuditEventPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlatformAuditEvent)]),
          ) as BuiltList<PlatformAuditEvent>;
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
  PlatformAuditEventPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlatformAuditEventPageBuilder();
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


