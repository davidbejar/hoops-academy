//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:hoops_core_api/src/model/approval_request.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'approval_request_page.g.dart';

/// ApprovalRequestPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class ApprovalRequestPage implements Built<ApprovalRequestPage, ApprovalRequestPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<ApprovalRequest> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  ApprovalRequestPage._();

  factory ApprovalRequestPage([void updates(ApprovalRequestPageBuilder b)]) = _$ApprovalRequestPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ApprovalRequestPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ApprovalRequestPage> get serializer => _$ApprovalRequestPageSerializer();
}

class _$ApprovalRequestPageSerializer implements PrimitiveSerializer<ApprovalRequestPage> {
  @override
  final Iterable<Type> types = const [ApprovalRequestPage, _$ApprovalRequestPage];

  @override
  final String wireName = r'ApprovalRequestPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ApprovalRequestPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(ApprovalRequest)]),
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
    ApprovalRequestPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ApprovalRequestPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ApprovalRequest)]),
          ) as BuiltList<ApprovalRequest>;
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
  ApprovalRequestPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ApprovalRequestPageBuilder();
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


