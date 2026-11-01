// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_me_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMeRequest extends UpdateMeRequest {
  @override
  final Locale locale;

  factory _$UpdateMeRequest([void Function(UpdateMeRequestBuilder)? updates]) =>
      (UpdateMeRequestBuilder()..update(updates))._build();

  _$UpdateMeRequest._({required this.locale}) : super._();
  @override
  UpdateMeRequest rebuild(void Function(UpdateMeRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateMeRequestBuilder toBuilder() => UpdateMeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateMeRequest && locale == other.locale;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateMeRequest')
          ..add('locale', locale))
        .toString();
  }
}

class UpdateMeRequestBuilder
    implements Builder<UpdateMeRequest, UpdateMeRequestBuilder> {
  _$UpdateMeRequest? _$v;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  UpdateMeRequestBuilder() {
    UpdateMeRequest._defaults(this);
  }

  UpdateMeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _locale = $v.locale;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateMeRequest other) {
    _$v = other as _$UpdateMeRequest;
  }

  @override
  void update(void Function(UpdateMeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateMeRequest build() => _build();

  _$UpdateMeRequest _build() {
    final _$result = _$v ??
        _$UpdateMeRequest._(
          locale: BuiltValueNullFieldError.checkNotNull(
              locale, r'UpdateMeRequest', 'locale'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
