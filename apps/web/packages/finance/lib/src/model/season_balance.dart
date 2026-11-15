//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hoops_finance_api/src/model/date.dart';
import 'package:hoops_finance_api/src/model/balance_income.dart';
import 'package:hoops_finance_api/src/model/balance_expenses.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'season_balance.g.dart';

/// SeasonBalance
///
/// Properties:
/// * [seasonId]
/// * [from] - The season's first day.
/// * [to] - The season's last day.
/// * [currency] - Alphabetic ISO 4217 code of the academy's currency.
/// * [income]
/// * [expenses]
/// * [netMinor] - Paid dues minus expenses (may be negative).
@BuiltValue()
abstract class SeasonBalance implements Built<SeasonBalance, SeasonBalanceBuilder> {
  @BuiltValueField(wireName: r'seasonId')
  String get seasonId;

  /// The season's first day.
  @BuiltValueField(wireName: r'from')
  Date get from;

  /// The season's last day.
  @BuiltValueField(wireName: r'to')
  Date get to;

  /// Alphabetic ISO 4217 code of the academy's currency.
  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'income')
  BalanceIncome get income;

  @BuiltValueField(wireName: r'expenses')
  BalanceExpenses get expenses;

  /// Paid dues minus expenses (may be negative).
  @BuiltValueField(wireName: r'netMinor')
  int get netMinor;

  SeasonBalance._();

  factory SeasonBalance([void updates(SeasonBalanceBuilder b)]) = _$SeasonBalance;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeasonBalanceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeasonBalance> get serializer => _$SeasonBalanceSerializer();
}

class _$SeasonBalanceSerializer implements PrimitiveSerializer<SeasonBalance> {
  @override
  final Iterable<Type> types = const [SeasonBalance, _$SeasonBalance];

  @override
  final String wireName = r'SeasonBalance';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeasonBalance object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'seasonId';
    yield serializers.serialize(
      object.seasonId,
      specifiedType: const FullType(String),
    );
    yield r'from';
    yield serializers.serialize(
      object.from,
      specifiedType: const FullType(Date),
    );
    yield r'to';
    yield serializers.serialize(
      object.to,
      specifiedType: const FullType(Date),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
    yield r'income';
    yield serializers.serialize(
      object.income,
      specifiedType: const FullType(BalanceIncome),
    );
    yield r'expenses';
    yield serializers.serialize(
      object.expenses,
      specifiedType: const FullType(BalanceExpenses),
    );
    yield r'netMinor';
    yield serializers.serialize(
      object.netMinor,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SeasonBalance object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SeasonBalanceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'seasonId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.seasonId = valueDes;
          break;
        case r'from':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.from = valueDes;
          break;
        case r'to':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.to = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        case r'income':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BalanceIncome),
          ) as BalanceIncome;
          result.income.replace(valueDes);
          break;
        case r'expenses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BalanceExpenses),
          ) as BalanceExpenses;
          result.expenses.replace(valueDes);
          break;
        case r'netMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.netMinor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SeasonBalance deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeasonBalanceBuilder();
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
