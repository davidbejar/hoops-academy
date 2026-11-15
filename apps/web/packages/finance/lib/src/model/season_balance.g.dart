// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_balance.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SeasonBalance extends SeasonBalance {
  @override
  final String seasonId;
  @override
  final Date from;
  @override
  final Date to;
  @override
  final String currency;
  @override
  final BalanceIncome income;
  @override
  final BalanceExpenses expenses;
  @override
  final int netMinor;

  factory _$SeasonBalance([void Function(SeasonBalanceBuilder)? updates]) =>
      (SeasonBalanceBuilder()..update(updates))._build();

  _$SeasonBalance._(
      {required this.seasonId,
      required this.from,
      required this.to,
      required this.currency,
      required this.income,
      required this.expenses,
      required this.netMinor})
      : super._();
  @override
  SeasonBalance rebuild(void Function(SeasonBalanceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeasonBalanceBuilder toBuilder() => SeasonBalanceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SeasonBalance &&
        seasonId == other.seasonId &&
        from == other.from &&
        to == other.to &&
        currency == other.currency &&
        income == other.income &&
        expenses == other.expenses &&
        netMinor == other.netMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, from.hashCode);
    _$hash = $jc(_$hash, to.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, income.hashCode);
    _$hash = $jc(_$hash, expenses.hashCode);
    _$hash = $jc(_$hash, netMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SeasonBalance')
          ..add('seasonId', seasonId)
          ..add('from', from)
          ..add('to', to)
          ..add('currency', currency)
          ..add('income', income)
          ..add('expenses', expenses)
          ..add('netMinor', netMinor))
        .toString();
  }
}

class SeasonBalanceBuilder
    implements Builder<SeasonBalance, SeasonBalanceBuilder> {
  _$SeasonBalance? _$v;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

  Date? _from;
  Date? get from => _$this._from;
  set from(Date? from) => _$this._from = from;

  Date? _to;
  Date? get to => _$this._to;
  set to(Date? to) => _$this._to = to;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  BalanceIncomeBuilder? _income;
  BalanceIncomeBuilder get income => _$this._income ??= BalanceIncomeBuilder();
  set income(BalanceIncomeBuilder? income) => _$this._income = income;

  BalanceExpensesBuilder? _expenses;
  BalanceExpensesBuilder get expenses =>
      _$this._expenses ??= BalanceExpensesBuilder();
  set expenses(BalanceExpensesBuilder? expenses) => _$this._expenses = expenses;

  int? _netMinor;
  int? get netMinor => _$this._netMinor;
  set netMinor(int? netMinor) => _$this._netMinor = netMinor;

  SeasonBalanceBuilder() {
    SeasonBalance._defaults(this);
  }

  SeasonBalanceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _seasonId = $v.seasonId;
      _from = $v.from;
      _to = $v.to;
      _currency = $v.currency;
      _income = $v.income.toBuilder();
      _expenses = $v.expenses.toBuilder();
      _netMinor = $v.netMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SeasonBalance other) {
    _$v = other as _$SeasonBalance;
  }

  @override
  void update(void Function(SeasonBalanceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SeasonBalance build() => _build();

  _$SeasonBalance _build() {
    _$SeasonBalance _$result;
    try {
      _$result = _$v ??
          _$SeasonBalance._(
            seasonId: BuiltValueNullFieldError.checkNotNull(
                seasonId, r'SeasonBalance', 'seasonId'),
            from: BuiltValueNullFieldError.checkNotNull(
                from, r'SeasonBalance', 'from'),
            to: BuiltValueNullFieldError.checkNotNull(
                to, r'SeasonBalance', 'to'),
            currency: BuiltValueNullFieldError.checkNotNull(
                currency, r'SeasonBalance', 'currency'),
            income: income.build(),
            expenses: expenses.build(),
            netMinor: BuiltValueNullFieldError.checkNotNull(
                netMinor, r'SeasonBalance', 'netMinor'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'income';
        income.build();
        _$failedField = 'expenses';
        expenses.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SeasonBalance', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
