//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:hoops_finance_api/src/date_serializer.dart';
import 'package:hoops_finance_api/src/model/date.dart';

import 'package:hoops_finance_api/src/model/balance_expenses.dart';
import 'package:hoops_finance_api/src/model/balance_income.dart';
import 'package:hoops_finance_api/src/model/category_total.dart';
import 'package:hoops_finance_api/src/model/change_due_amount_request.dart';
import 'package:hoops_finance_api/src/model/create_expense_request.dart';
import 'package:hoops_finance_api/src/model/create_fee_plan_request.dart';
import 'package:hoops_finance_api/src/model/due.dart';
import 'package:hoops_finance_api/src/model/due_detail.dart';
import 'package:hoops_finance_api/src/model/due_generation.dart';
import 'package:hoops_finance_api/src/model/due_page.dart';
import 'package:hoops_finance_api/src/model/due_status.dart';
import 'package:hoops_finance_api/src/model/expense.dart';
import 'package:hoops_finance_api/src/model/expense_category.dart';
import 'package:hoops_finance_api/src/model/expense_page.dart';
import 'package:hoops_finance_api/src/model/fee_cadence.dart';
import 'package:hoops_finance_api/src/model/fee_plan.dart';
import 'package:hoops_finance_api/src/model/fee_plan_page.dart';
import 'package:hoops_finance_api/src/model/finance_settings.dart';
import 'package:hoops_finance_api/src/model/generate_dues_request.dart';
import 'package:hoops_finance_api/src/model/generated_due.dart';
import 'package:hoops_finance_api/src/model/page_meta.dart';
import 'package:hoops_finance_api/src/model/pay_due_request.dart';
import 'package:hoops_finance_api/src/model/payment.dart';
import 'package:hoops_finance_api/src/model/payment_method.dart';
import 'package:hoops_finance_api/src/model/person_ref.dart';
import 'package:hoops_finance_api/src/model/player_due.dart';
import 'package:hoops_finance_api/src/model/player_due_page.dart';
import 'package:hoops_finance_api/src/model/player_due_status.dart';
import 'package:hoops_finance_api/src/model/problem.dart';
import 'package:hoops_finance_api/src/model/problem_violation.dart';
import 'package:hoops_finance_api/src/model/reason_request.dart';
import 'package:hoops_finance_api/src/model/season_balance.dart';
import 'package:hoops_finance_api/src/model/team_due_status.dart';
import 'package:hoops_finance_api/src/model/update_expense_request.dart';
import 'package:hoops_finance_api/src/model/update_fee_plan_request.dart';
import 'package:hoops_finance_api/src/model/update_finance_settings_request.dart';

part 'serializers.g.dart';

@SerializersFor([
  BalanceExpenses,
  BalanceIncome,
  CategoryTotal,
  ChangeDueAmountRequest,
  CreateExpenseRequest,
  CreateFeePlanRequest,
  Due,
  DueDetail,
  DueGeneration,
  DuePage,
  DueStatus,
  Expense,
  ExpenseCategory,
  ExpensePage,
  FeeCadence,
  FeePlan,
  FeePlanPage,
  FinanceSettings,
  GenerateDuesRequest,
  GeneratedDue,
  PageMeta,
  PayDueRequest,
  Payment,
  PaymentMethod,
  PersonRef,
  PlayerDue,
  PlayerDuePage,
  PlayerDueStatus,
  Problem,
  ProblemViolation,
  ReasonRequest,
  SeasonBalance,
  TeamDueStatus,
  UpdateExpenseRequest,
  UpdateFeePlanRequest,
  UpdateFinanceSettingsRequest,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Due)]),
        () => ListBuilder<Due>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GeneratedDue)]),
        () => ListBuilder<GeneratedDue>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltSet, [FullType(String)]),
        () => SetBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerDue)]),
        () => ListBuilder<PlayerDue>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(FeePlan)]),
        () => ListBuilder<FeePlan>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerDueStatus)]),
        () => ListBuilder<PlayerDueStatus>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Expense)]),
        () => ListBuilder<Expense>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Payment)]),
        () => ListBuilder<Payment>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(CategoryTotal)]),
        () => ListBuilder<CategoryTotal>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ProblemViolation)]),
        () => ListBuilder<ProblemViolation>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
