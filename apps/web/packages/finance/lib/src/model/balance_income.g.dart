// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_income.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BalanceIncome extends BalanceIncome {
  @override
  final int paidMinor;
  @override
  final int openMinor;
  @override
  final int waivedMinor;

  factory _$BalanceIncome([void Function(BalanceIncomeBuilder)? updates]) =>
      (BalanceIncomeBuilder()..update(updates))._build();

  _$BalanceIncome._(
      {required this.paidMinor,
      required this.openMinor,
      required this.waivedMinor})
      : super._();
  @override
  BalanceIncome rebuild(void Function(BalanceIncomeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BalanceIncomeBuilder toBuilder() => BalanceIncomeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BalanceIncome &&
        paidMinor == other.paidMinor &&
        openMinor == other.openMinor &&
        waivedMinor == other.waivedMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, paidMinor.hashCode);
    _$hash = $jc(_$hash, openMinor.hashCode);
    _$hash = $jc(_$hash, waivedMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BalanceIncome')
          ..add('paidMinor', paidMinor)
          ..add('openMinor', openMinor)
          ..add('waivedMinor', waivedMinor))
        .toString();
  }
}

class BalanceIncomeBuilder
    implements Builder<BalanceIncome, BalanceIncomeBuilder> {
  _$BalanceIncome? _$v;

  int? _paidMinor;
  int? get paidMinor => _$this._paidMinor;
  set paidMinor(int? paidMinor) => _$this._paidMinor = paidMinor;

  int? _openMinor;
  int? get openMinor => _$this._openMinor;
  set openMinor(int? openMinor) => _$this._openMinor = openMinor;

  int? _waivedMinor;
  int? get waivedMinor => _$this._waivedMinor;
  set waivedMinor(int? waivedMinor) => _$this._waivedMinor = waivedMinor;

  BalanceIncomeBuilder() {
    BalanceIncome._defaults(this);
  }

  BalanceIncomeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _paidMinor = $v.paidMinor;
      _openMinor = $v.openMinor;
      _waivedMinor = $v.waivedMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BalanceIncome other) {
    _$v = other as _$BalanceIncome;
  }

  @override
  void update(void Function(BalanceIncomeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BalanceIncome build() => _build();

  _$BalanceIncome _build() {
    final _$result = _$v ??
        _$BalanceIncome._(
          paidMinor: BuiltValueNullFieldError.checkNotNull(
              paidMinor, r'BalanceIncome', 'paidMinor'),
          openMinor: BuiltValueNullFieldError.checkNotNull(
              openMinor, r'BalanceIncome', 'openMinor'),
          waivedMinor: BuiltValueNullFieldError.checkNotNull(
              waivedMinor, r'BalanceIncome', 'waivedMinor'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
