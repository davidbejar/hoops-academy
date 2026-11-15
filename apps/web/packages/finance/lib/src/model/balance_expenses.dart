//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:hoops_finance_api/src/model/category_total.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'balance_expenses.g.dart';

/// BalanceExpenses
///
/// Properties:
/// * [totalMinor]
/// * [byCategory] - One entry per category, in the enum's order, zero included.
@BuiltValue()
abstract class BalanceExpenses implements Built<BalanceExpenses, BalanceExpensesBuilder> {
  @BuiltValueField(wireName: r'totalMinor')
  int get totalMinor;

  /// One entry per category, in the enum's order, zero included.
  @BuiltValueField(wireName: r'byCategory')
  BuiltList<CategoryTotal> get byCategory;

  BalanceExpenses._();

  factory BalanceExpenses([void updates(BalanceExpensesBuilder b)]) = _$BalanceExpenses;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BalanceExpensesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BalanceExpenses> get serializer => _$BalanceExpensesSerializer();
}

class _$BalanceExpensesSerializer implements PrimitiveSerializer<BalanceExpenses> {
  @override
  final Iterable<Type> types = const [BalanceExpenses, _$BalanceExpenses];

  @override
  final String wireName = r'BalanceExpenses';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BalanceExpenses object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'totalMinor';
    yield serializers.serialize(
      object.totalMinor,
      specifiedType: const FullType(int),
    );
    yield r'byCategory';
    yield serializers.serialize(
      object.byCategory,
      specifiedType: const FullType(BuiltList, [FullType(CategoryTotal)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BalanceExpenses object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BalanceExpensesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'totalMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalMinor = valueDes;
          break;
        case r'byCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CategoryTotal)]),
          ) as BuiltList<CategoryTotal>;
          result.byCategory.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BalanceExpenses deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BalanceExpensesBuilder();
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
