// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_settings.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FinanceSettings extends FinanceSettings {
  @override
  final String? currency;
  @override
  final int? minorDigits;
  @override
  final bool currencyLocked;

  factory _$FinanceSettings([void Function(FinanceSettingsBuilder)? updates]) =>
      (FinanceSettingsBuilder()..update(updates))._build();

  _$FinanceSettings._(
      {this.currency, this.minorDigits, required this.currencyLocked})
      : super._();
  @override
  FinanceSettings rebuild(void Function(FinanceSettingsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FinanceSettingsBuilder toBuilder() => FinanceSettingsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FinanceSettings &&
        currency == other.currency &&
        minorDigits == other.minorDigits &&
        currencyLocked == other.currencyLocked;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, minorDigits.hashCode);
    _$hash = $jc(_$hash, currencyLocked.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FinanceSettings')
          ..add('currency', currency)
          ..add('minorDigits', minorDigits)
          ..add('currencyLocked', currencyLocked))
        .toString();
  }
}

class FinanceSettingsBuilder
    implements Builder<FinanceSettings, FinanceSettingsBuilder> {
  _$FinanceSettings? _$v;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  int? _minorDigits;
  int? get minorDigits => _$this._minorDigits;
  set minorDigits(int? minorDigits) => _$this._minorDigits = minorDigits;

  bool? _currencyLocked;
  bool? get currencyLocked => _$this._currencyLocked;
  set currencyLocked(bool? currencyLocked) =>
      _$this._currencyLocked = currencyLocked;

  FinanceSettingsBuilder() {
    FinanceSettings._defaults(this);
  }

  FinanceSettingsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currency = $v.currency;
      _minorDigits = $v.minorDigits;
      _currencyLocked = $v.currencyLocked;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FinanceSettings other) {
    _$v = other as _$FinanceSettings;
  }

  @override
  void update(void Function(FinanceSettingsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FinanceSettings build() => _build();

  _$FinanceSettings _build() {
    final _$result = _$v ??
        _$FinanceSettings._(
          currency: currency,
          minorDigits: minorDigits,
          currencyLocked: BuiltValueNullFieldError.checkNotNull(
              currencyLocked, r'FinanceSettings', 'currencyLocked'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
