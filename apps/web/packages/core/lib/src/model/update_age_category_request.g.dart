// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_age_category_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateAgeCategoryRequest extends UpdateAgeCategoryRequest {
  @override
  final String? code;
  @override
  final String? name;
  @override
  final int? maxAge;
  @override
  final int? rank;

  factory _$UpdateAgeCategoryRequest(
          [void Function(UpdateAgeCategoryRequestBuilder)? updates]) =>
      (UpdateAgeCategoryRequestBuilder()..update(updates))._build();

  _$UpdateAgeCategoryRequest._({this.code, this.name, this.maxAge, this.rank})
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
        rank == other.rank;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, maxAge.hashCode);
    _$hash = $jc(_$hash, rank.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateAgeCategoryRequest')
          ..add('code', code)
          ..add('name', name)
          ..add('maxAge', maxAge)
          ..add('rank', rank))
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
    final _$result = _$v ??
        _$UpdateAgeCategoryRequest._(
          code: code,
          name: name,
          maxAge: maxAge,
          rank: rank,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
