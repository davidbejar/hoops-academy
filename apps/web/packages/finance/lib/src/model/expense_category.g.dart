// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ExpenseCategory _$COURT_RENTAL = const ExpenseCategory._('COURT_RENTAL');
const ExpenseCategory _$SALARIES = const ExpenseCategory._('SALARIES');
const ExpenseCategory _$KIT = const ExpenseCategory._('KIT');
const ExpenseCategory _$TOURNAMENT_FEES =
    const ExpenseCategory._('TOURNAMENT_FEES');
const ExpenseCategory _$TRAVEL = const ExpenseCategory._('TRAVEL');
const ExpenseCategory _$OTHER = const ExpenseCategory._('OTHER');
const ExpenseCategory _$unknownDefaultOpenApi =
    const ExpenseCategory._('unknownDefaultOpenApi');

ExpenseCategory _$valueOf(String name) {
  switch (name) {
    case 'COURT_RENTAL':
      return _$COURT_RENTAL;
    case 'SALARIES':
      return _$SALARIES;
    case 'KIT':
      return _$KIT;
    case 'TOURNAMENT_FEES':
      return _$TOURNAMENT_FEES;
    case 'TRAVEL':
      return _$TRAVEL;
    case 'OTHER':
      return _$OTHER;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<ExpenseCategory> _$values =
    BuiltSet<ExpenseCategory>(const <ExpenseCategory>[
  _$COURT_RENTAL,
  _$SALARIES,
  _$KIT,
  _$TOURNAMENT_FEES,
  _$TRAVEL,
  _$OTHER,
  _$unknownDefaultOpenApi,
]);

class _$ExpenseCategoryMeta {
  const _$ExpenseCategoryMeta();
  ExpenseCategory get COURT_RENTAL => _$COURT_RENTAL;
  ExpenseCategory get SALARIES => _$SALARIES;
  ExpenseCategory get KIT => _$KIT;
  ExpenseCategory get TOURNAMENT_FEES => _$TOURNAMENT_FEES;
  ExpenseCategory get TRAVEL => _$TRAVEL;
  ExpenseCategory get OTHER => _$OTHER;
  ExpenseCategory get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  ExpenseCategory valueOf(String name) => _$valueOf(name);
  BuiltSet<ExpenseCategory> get values => _$values;
}

abstract class _$ExpenseCategoryMixin {
  // ignore: non_constant_identifier_names
  _$ExpenseCategoryMeta get ExpenseCategory => const _$ExpenseCategoryMeta();
}

Serializer<ExpenseCategory> _$expenseCategorySerializer =
    _$ExpenseCategorySerializer();

class _$ExpenseCategorySerializer
    implements PrimitiveSerializer<ExpenseCategory> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'COURT_RENTAL': 'COURT_RENTAL',
    'SALARIES': 'SALARIES',
    'KIT': 'KIT',
    'TOURNAMENT_FEES': 'TOURNAMENT_FEES',
    'TRAVEL': 'TRAVEL',
    'OTHER': 'OTHER',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'COURT_RENTAL': 'COURT_RENTAL',
    'SALARIES': 'SALARIES',
    'KIT': 'KIT',
    'TOURNAMENT_FEES': 'TOURNAMENT_FEES',
    'TRAVEL': 'TRAVEL',
    'OTHER': 'OTHER',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ExpenseCategory];
  @override
  final String wireName = 'ExpenseCategory';

  @override
  Object serialize(Serializers serializers, ExpenseCategory object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ExpenseCategory deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ExpenseCategory.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
