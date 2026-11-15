//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expense_category.g.dart';

/// The fixed categories of decision 99 (labels are the web's).
class ExpenseCategory extends EnumClass {

  @BuiltValueEnumConst(wireName: r'COURT_RENTAL')
  static const ExpenseCategory COURT_RENTAL = _$COURT_RENTAL;
  @BuiltValueEnumConst(wireName: r'SALARIES')
  static const ExpenseCategory SALARIES = _$SALARIES;
  @BuiltValueEnumConst(wireName: r'KIT')
  static const ExpenseCategory KIT = _$KIT;
  @BuiltValueEnumConst(wireName: r'TOURNAMENT_FEES')
  static const ExpenseCategory TOURNAMENT_FEES = _$TOURNAMENT_FEES;
  @BuiltValueEnumConst(wireName: r'TRAVEL')
  static const ExpenseCategory TRAVEL = _$TRAVEL;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const ExpenseCategory OTHER = _$OTHER;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ExpenseCategory unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ExpenseCategory> get serializer => _$expenseCategorySerializer;

  const ExpenseCategory._(String name): super(name);

  static BuiltSet<ExpenseCategory> get values => _$values;
  static ExpenseCategory valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ExpenseCategoryMixin = Object with _$ExpenseCategoryMixin;
