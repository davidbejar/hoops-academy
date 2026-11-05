// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_category_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AgeCategoryInput extends AgeCategoryInput {
  @override
  final String code;
  @override
  final String name;
  @override
  final int? maxAge;
  @override
  final int rank;

  factory _$AgeCategoryInput(
          [void Function(AgeCategoryInputBuilder)? updates]) =>
      (AgeCategoryInputBuilder()..update(updates))._build();

  _$AgeCategoryInput._(
      {required this.code, required this.name, this.maxAge, required this.rank})
      : super._();
  @override
  AgeCategoryInput rebuild(void Function(AgeCategoryInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AgeCategoryInputBuilder toBuilder() =>
      AgeCategoryInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AgeCategoryInput &&
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
    return (newBuiltValueToStringHelper(r'AgeCategoryInput')
          ..add('code', code)
          ..add('name', name)
          ..add('maxAge', maxAge)
          ..add('rank', rank))
        .toString();
  }
}

class AgeCategoryInputBuilder
    implements Builder<AgeCategoryInput, AgeCategoryInputBuilder> {
  _$AgeCategoryInput? _$v;

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

  AgeCategoryInputBuilder() {
    AgeCategoryInput._defaults(this);
  }

  AgeCategoryInputBuilder get _$this {
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
  void replace(AgeCategoryInput other) {
    _$v = other as _$AgeCategoryInput;
  }

  @override
  void update(void Function(AgeCategoryInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AgeCategoryInput build() => _build();

  _$AgeCategoryInput _build() {
    final _$result = _$v ??
        _$AgeCategoryInput._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'AgeCategoryInput', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'AgeCategoryInput', 'name'),
          maxAge: maxAge,
          rank: BuiltValueNullFieldError.checkNotNull(
              rank, r'AgeCategoryInput', 'rank'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
