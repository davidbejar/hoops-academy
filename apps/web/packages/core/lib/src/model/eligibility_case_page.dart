//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_core_api/src/model/page_meta.dart';
import 'package:hoops_core_api/src/model/eligibility_case.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_case_page.g.dart';

/// EligibilityCasePage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class EligibilityCasePage
    implements Built<EligibilityCasePage, EligibilityCasePageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<EligibilityCase> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  EligibilityCasePage._();

  factory EligibilityCasePage([void updates(EligibilityCasePageBuilder b)]) =
      _$EligibilityCasePage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EligibilityCasePageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EligibilityCasePage> get serializer =>
      _$EligibilityCasePageSerializer();
}

class _$EligibilityCasePageSerializer
    implements PrimitiveSerializer<EligibilityCasePage> {
  @override
  final Iterable<Type> types = const [
    EligibilityCasePage,
    _$EligibilityCasePage
  ];

  @override
  final String wireName = r'EligibilityCasePage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EligibilityCasePage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(EligibilityCase)]),
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
    EligibilityCasePage object, {
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
    required EligibilityCasePageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(EligibilityCase)]),
          ) as BuiltList<EligibilityCase>;
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
  EligibilityCasePage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EligibilityCasePageBuilder();
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
