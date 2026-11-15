// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_dues_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GenerateDuesRequest extends GenerateDuesRequest {
  @override
  final String period;
  @override
  final bool? preview;

  factory _$GenerateDuesRequest(
          [void Function(GenerateDuesRequestBuilder)? updates]) =>
      (GenerateDuesRequestBuilder()..update(updates))._build();

  _$GenerateDuesRequest._({required this.period, this.preview}) : super._();
  @override
  GenerateDuesRequest rebuild(
          void Function(GenerateDuesRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GenerateDuesRequestBuilder toBuilder() =>
      GenerateDuesRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GenerateDuesRequest &&
        period == other.period &&
        preview == other.preview;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, preview.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GenerateDuesRequest')
          ..add('period', period)
          ..add('preview', preview))
        .toString();
  }
}

class GenerateDuesRequestBuilder
    implements Builder<GenerateDuesRequest, GenerateDuesRequestBuilder> {
  _$GenerateDuesRequest? _$v;

  String? _period;
  String? get period => _$this._period;
  set period(String? period) => _$this._period = period;

  bool? _preview;
  bool? get preview => _$this._preview;
  set preview(bool? preview) => _$this._preview = preview;

  GenerateDuesRequestBuilder() {
    GenerateDuesRequest._defaults(this);
  }

  GenerateDuesRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _period = $v.period;
      _preview = $v.preview;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GenerateDuesRequest other) {
    _$v = other as _$GenerateDuesRequest;
  }

  @override
  void update(void Function(GenerateDuesRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GenerateDuesRequest build() => _build();

  _$GenerateDuesRequest _build() {
    final _$result = _$v ??
        _$GenerateDuesRequest._(
          period: BuiltValueNullFieldError.checkNotNull(
              period, r'GenerateDuesRequest', 'period'),
          preview: preview,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
