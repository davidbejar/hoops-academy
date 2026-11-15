// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_fee_plan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateFeePlanRequestClearEnum _$updateFeePlanRequestClearEnum_lastPeriod =
    const UpdateFeePlanRequestClearEnum._('lastPeriod');
const UpdateFeePlanRequestClearEnum
    _$updateFeePlanRequestClearEnum_unknownDefaultOpenApi =
    const UpdateFeePlanRequestClearEnum._('unknownDefaultOpenApi');

UpdateFeePlanRequestClearEnum _$updateFeePlanRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'lastPeriod':
      return _$updateFeePlanRequestClearEnum_lastPeriod;
    case 'unknownDefaultOpenApi':
      return _$updateFeePlanRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateFeePlanRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateFeePlanRequestClearEnum>
    _$updateFeePlanRequestClearEnumValues = BuiltSet<
        UpdateFeePlanRequestClearEnum>(const <UpdateFeePlanRequestClearEnum>[
  _$updateFeePlanRequestClearEnum_lastPeriod,
  _$updateFeePlanRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateFeePlanRequestClearEnum>
    _$updateFeePlanRequestClearEnumSerializer =
    _$UpdateFeePlanRequestClearEnumSerializer();

class _$UpdateFeePlanRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateFeePlanRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'lastPeriod': 'lastPeriod',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'lastPeriod': 'lastPeriod',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateFeePlanRequestClearEnum];
  @override
  final String wireName = 'UpdateFeePlanRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateFeePlanRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateFeePlanRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateFeePlanRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateFeePlanRequest extends UpdateFeePlanRequest {
  @override
  final String? name;
  @override
  final int? amountMinor;
  @override
  final String? firstPeriod;
  @override
  final String? lastPeriod;
  @override
  final bool? autoGenerate;
  @override
  final BuiltSet<UpdateFeePlanRequestClearEnum>? clear;

  factory _$UpdateFeePlanRequest(
          [void Function(UpdateFeePlanRequestBuilder)? updates]) =>
      (UpdateFeePlanRequestBuilder()..update(updates))._build();

  _$UpdateFeePlanRequest._(
      {this.name,
      this.amountMinor,
      this.firstPeriod,
      this.lastPeriod,
      this.autoGenerate,
      this.clear})
      : super._();
  @override
  UpdateFeePlanRequest rebuild(
          void Function(UpdateFeePlanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateFeePlanRequestBuilder toBuilder() =>
      UpdateFeePlanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateFeePlanRequest &&
        name == other.name &&
        amountMinor == other.amountMinor &&
        firstPeriod == other.firstPeriod &&
        lastPeriod == other.lastPeriod &&
        autoGenerate == other.autoGenerate &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, firstPeriod.hashCode);
    _$hash = $jc(_$hash, lastPeriod.hashCode);
    _$hash = $jc(_$hash, autoGenerate.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateFeePlanRequest')
          ..add('name', name)
          ..add('amountMinor', amountMinor)
          ..add('firstPeriod', firstPeriod)
          ..add('lastPeriod', lastPeriod)
          ..add('autoGenerate', autoGenerate)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateFeePlanRequestBuilder
    implements Builder<UpdateFeePlanRequest, UpdateFeePlanRequestBuilder> {
  _$UpdateFeePlanRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _firstPeriod;
  String? get firstPeriod => _$this._firstPeriod;
  set firstPeriod(String? firstPeriod) => _$this._firstPeriod = firstPeriod;

  String? _lastPeriod;
  String? get lastPeriod => _$this._lastPeriod;
  set lastPeriod(String? lastPeriod) => _$this._lastPeriod = lastPeriod;

  bool? _autoGenerate;
  bool? get autoGenerate => _$this._autoGenerate;
  set autoGenerate(bool? autoGenerate) => _$this._autoGenerate = autoGenerate;

  SetBuilder<UpdateFeePlanRequestClearEnum>? _clear;
  SetBuilder<UpdateFeePlanRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateFeePlanRequestClearEnum>();
  set clear(SetBuilder<UpdateFeePlanRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateFeePlanRequestBuilder() {
    UpdateFeePlanRequest._defaults(this);
  }

  UpdateFeePlanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _amountMinor = $v.amountMinor;
      _firstPeriod = $v.firstPeriod;
      _lastPeriod = $v.lastPeriod;
      _autoGenerate = $v.autoGenerate;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateFeePlanRequest other) {
    _$v = other as _$UpdateFeePlanRequest;
  }

  @override
  void update(void Function(UpdateFeePlanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateFeePlanRequest build() => _build();

  _$UpdateFeePlanRequest _build() {
    _$UpdateFeePlanRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateFeePlanRequest._(
            name: name,
            amountMinor: amountMinor,
            firstPeriod: firstPeriod,
            lastPeriod: lastPeriod,
            autoGenerate: autoGenerate,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateFeePlanRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
