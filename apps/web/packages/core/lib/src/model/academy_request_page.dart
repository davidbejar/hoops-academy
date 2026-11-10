//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_core_api/src/model/academy_request.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'academy_request_page.g.dart';

/// AcademyRequestPage
///
/// Properties:
/// * [items] 
/// * [page] 
@BuiltValue()
abstract class AcademyRequestPage implements Built<AcademyRequestPage, AcademyRequestPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<AcademyRequest> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  AcademyRequestPage._();

  factory AcademyRequestPage([void updates(AcademyRequestPageBuilder b)]) = _$AcademyRequestPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcademyRequestPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcademyRequestPage> get serializer => _$AcademyRequestPageSerializer();
}

class _$AcademyRequestPageSerializer implements PrimitiveSerializer<AcademyRequestPage> {
  @override
  final Iterable<Type> types = const [AcademyRequestPage, _$AcademyRequestPage];

  @override
  final String wireName = r'AcademyRequestPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcademyRequestPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(AcademyRequest)]),
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
    AcademyRequestPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AcademyRequestPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AcademyRequest)]),
          ) as BuiltList<AcademyRequest>;
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
  AcademyRequestPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcademyRequestPageBuilder();
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


