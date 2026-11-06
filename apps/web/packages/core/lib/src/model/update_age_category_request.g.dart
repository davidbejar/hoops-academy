// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_age_category_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateAgeCategoryRequestClearEnum
    _$updateAgeCategoryRequestClearEnum_maxAge =
    const UpdateAgeCategoryRequestClearEnum._('maxAge');
const UpdateAgeCategoryRequestClearEnum
    _$updateAgeCategoryRequestClearEnum_unknownDefaultOpenApi =
    const UpdateAgeCategoryRequestClearEnum._('unknownDefaultOpenApi');

UpdateAgeCategoryRequestClearEnum _$updateAgeCategoryRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'maxAge':
      return _$updateAgeCategoryRequestClearEnum_maxAge;
    case 'unknownDefaultOpenApi':
      return _$updateAgeCategoryRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateAgeCategoryRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateAgeCategoryRequestClearEnum>
    _$updateAgeCategoryRequestClearEnumValues = BuiltSet<
        UpdateAgeCategoryRequestClearEnum>(const <UpdateAgeCategoryRequestClearEnum>[
  _$updateAgeCategoryRequestClearEnum_maxAge,
  _$updateAgeCategoryRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateAgeCategoryRequestClearEnum>
    _$updateAgeCategoryRequestClearEnumSerializer =
    _$UpdateAgeCategoryRequestClearEnumSerializer();

class _$UpdateAgeCategoryRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateAgeCategoryRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'maxAge': 'maxAge',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'maxAge': 'maxAge',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateAgeCategoryRequestClearEnum];
  @override
  final String wireName = 'UpdateAgeCategoryRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateAgeCategoryRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateAgeCategoryRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateAgeCategoryRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateAgeCategoryRequest extends UpdateAgeCategoryRequest {
  @override
  final String? code;
  @override
  final String? name;
  @override
  final int? maxAge;
  @override
  final int? rank;
  @override
  final BuiltSet<UpdateAgeCategoryRequestClearEnum>? clear;

  factory _$UpdateAgeCategoryRequest(
          [void Function(UpdateAgeCategoryRequestBuilder)? updates]) =>
      (UpdateAgeCategoryRequestBuilder()..update(updates))._build();

  _$UpdateAgeCategoryRequest._(
      {this.code, this.name, this.maxAge, this.rank, this.clear})
      : super._();
  @override
  UpdateAgeCategoryRequest rebuild(
          void Function(UpdateAgeCategoryRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateAgeCategoryRequestBuilder toBuilder() =>
      UpdateAgeCategoryRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateAgeCategoryRequest &&
        code == other.code &&
        name == other.name &&
        maxAge == other.maxAge &&
        rank == other.rank &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, maxAge.hashCode);
    _$hash = $jc(_$hash, rank.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateAgeCategoryRequest')
          ..add('code', code)
          ..add('name', name)
          ..add('maxAge', maxAge)
          ..add('rank', rank)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateAgeCategoryRequestBuilder
    implements
        Builder<UpdateAgeCategoryRequest, UpdateAgeCategoryRequestBuilder> {
  _$UpdateAgeCategoryRequest? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _maxAge;
  int? get maxAge => _$this._maxAge;
  set maxAge(int? maxAge) => _$this._maxAge = maxAge;

  int? _rank;
  int? get rank => _$this._rank;
  set rank(int? rank) => _$this._rank = rank;

  SetBuilder<UpdateAgeCategoryRequestClearEnum>? _clear;
  SetBuilder<UpdateAgeCategoryRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateAgeCategoryRequestClearEnum>();
  set clear(SetBuilder<UpdateAgeCategoryRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateAgeCategoryRequestBuilder() {
    UpdateAgeCategoryRequest._defaults(this);
  }

  UpdateAgeCategoryRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _name = $v.name;
      _maxAge = $v.maxAge;
      _rank = $v.rank;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateAgeCategoryRequest other) {
    _$v = other as _$UpdateAgeCategoryRequest;
  }

  @override
  void update(void Function(UpdateAgeCategoryRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateAgeCategoryRequest build() => _build();

  _$UpdateAgeCategoryRequest _build() {
    _$UpdateAgeCategoryRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateAgeCategoryRequest._(
            code: code,
            name: name,
            maxAge: maxAge,
            rank: rank,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateAgeCategoryRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
