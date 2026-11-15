// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_finance_settings_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateFinanceSettingsRequest extends UpdateFinanceSettingsRequest {
  @override
  final String currency;

  factory _$UpdateFinanceSettingsRequest(
          [void Function(UpdateFinanceSettingsRequestBuilder)? updates]) =>
      (UpdateFinanceSettingsRequestBuilder()..update(updates))._build();

  _$UpdateFinanceSettingsRequest._({required this.currency}) : super._();
  @override
  UpdateFinanceSettingsRequest rebuild(
          void Function(UpdateFinanceSettingsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateFinanceSettingsRequestBuilder toBuilder() =>
      UpdateFinanceSettingsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateFinanceSettingsRequest && currency == other.currency;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateFinanceSettingsRequest')
          ..add('currency', currency))
        .toString();
  }
}

class UpdateFinanceSettingsRequestBuilder
    implements
        Builder<UpdateFinanceSettingsRequest,
            UpdateFinanceSettingsRequestBuilder> {
  _$UpdateFinanceSettingsRequest? _$v;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  UpdateFinanceSettingsRequestBuilder() {
    UpdateFinanceSettingsRequest._defaults(this);
  }

  UpdateFinanceSettingsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currency = $v.currency;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateFinanceSettingsRequest other) {
    _$v = other as _$UpdateFinanceSettingsRequest;
  }

  @override
  void update(void Function(UpdateFinanceSettingsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateFinanceSettingsRequest build() => _build();

  _$UpdateFinanceSettingsRequest _build() {
    final _$result = _$v ??
        _$UpdateFinanceSettingsRequest._(
          currency: BuiltValueNullFieldError.checkNotNull(
              currency, r'UpdateFinanceSettingsRequest', 'currency'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
