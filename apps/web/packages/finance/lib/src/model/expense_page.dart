//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/expense.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_finance_api/src/model/page_meta.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expense_page.g.dart';

/// ExpensePage
///
/// Properties:
/// * [items]
/// * [page]
@BuiltValue()
abstract class ExpensePage implements Built<ExpensePage, ExpensePageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Expense> get items;

  @BuiltValueField(wireName: r'page')
  PageMeta get page;

  ExpensePage._();

  factory ExpensePage([void updates(ExpensePageBuilder b)]) = _$ExpensePage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpensePageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpensePage> get serializer => _$ExpensePageSerializer();
}

class _$ExpensePageSerializer implements PrimitiveSerializer<ExpensePage> {
  @override
  final Iterable<Type> types = const [ExpensePage, _$ExpensePage];

  @override
  final String wireName = r'ExpensePage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpensePage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Expense)]),
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
    ExpensePage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExpensePageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Expense)]),
          ) as BuiltList<Expense>;
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
  ExpensePage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpensePageBuilder();
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
