// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_expenses.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BalanceExpenses extends BalanceExpenses {
  @override
  final int totalMinor;
  @override
  final BuiltList<CategoryTotal> byCategory;

  factory _$BalanceExpenses([void Function(BalanceExpensesBuilder)? updates]) =>
      (BalanceExpensesBuilder()..update(updates))._build();

  _$BalanceExpenses._({required this.totalMinor, required this.byCategory})
      : super._();
  @override
  BalanceExpenses rebuild(void Function(BalanceExpensesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BalanceExpensesBuilder toBuilder() => BalanceExpensesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BalanceExpenses &&
        totalMinor == other.totalMinor &&
        byCategory == other.byCategory;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, totalMinor.hashCode);
    _$hash = $jc(_$hash, byCategory.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BalanceExpenses')
          ..add('totalMinor', totalMinor)
          ..add('byCategory', byCategory))
        .toString();
  }
}

class BalanceExpensesBuilder
    implements Builder<BalanceExpenses, BalanceExpensesBuilder> {
  _$BalanceExpenses? _$v;

  int? _totalMinor;
  int? get totalMinor => _$this._totalMinor;
  set totalMinor(int? totalMinor) => _$this._totalMinor = totalMinor;

  ListBuilder<CategoryTotal>? _byCategory;
  ListBuilder<CategoryTotal> get byCategory =>
      _$this._byCategory ??= ListBuilder<CategoryTotal>();
  set byCategory(ListBuilder<CategoryTotal>? byCategory) =>
      _$this._byCategory = byCategory;

  BalanceExpensesBuilder() {
    BalanceExpenses._defaults(this);
  }

  BalanceExpensesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _totalMinor = $v.totalMinor;
      _byCategory = $v.byCategory.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BalanceExpenses other) {
    _$v = other as _$BalanceExpenses;
  }

  @override
  void update(void Function(BalanceExpensesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BalanceExpenses build() => _build();

  _$BalanceExpenses _build() {
    _$BalanceExpenses _$result;
    try {
      _$result = _$v ??
          _$BalanceExpenses._(
            totalMinor: BuiltValueNullFieldError.checkNotNull(
                totalMinor, r'BalanceExpenses', 'totalMinor'),
            byCategory: byCategory.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'byCategory';
        byCategory.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BalanceExpenses', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
