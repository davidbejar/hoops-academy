// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AgeCategory extends AgeCategory {
  @override
  final String code;
  @override
  final String name;
  @override
  final int? maxAge;
  @override
  final int rank;
  @override
  final String id;

  factory _$AgeCategory([void Function(AgeCategoryBuilder)? updates]) =>
      (AgeCategoryBuilder()..update(updates))._build();

  _$AgeCategory._(
      {required this.code,
      required this.name,
      this.maxAge,
      required this.rank,
      required this.id})
      : super._();
  @override
  AgeCategory rebuild(void Function(AgeCategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AgeCategoryBuilder toBuilder() => AgeCategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AgeCategory &&
        code == other.code &&
        name == other.name &&
        maxAge == other.maxAge &&
        rank == other.rank &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, maxAge.hashCode);
    _$hash = $jc(_$hash, rank.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AgeCategory')
          ..add('code', code)
          ..add('name', name)
          ..add('maxAge', maxAge)
          ..add('rank', rank)
          ..add('id', id))
        .toString();
  }
}

class AgeCategoryBuilder implements Builder<AgeCategory, AgeCategoryBuilder> {
  _$AgeCategory? _$v;

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

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  AgeCategoryBuilder() {
    AgeCategory._defaults(this);
  }

  AgeCategoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _name = $v.name;
      _maxAge = $v.maxAge;
      _rank = $v.rank;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AgeCategory other) {
    _$v = other as _$AgeCategory;
  }

  @override
  void update(void Function(AgeCategoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AgeCategory build() => _build();

  _$AgeCategory _build() {
    final _$result = _$v ??
        _$AgeCategory._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'AgeCategory', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'AgeCategory', 'name'),
          maxAge: maxAge,
          rank: BuiltValueNullFieldError.checkNotNull(
              rank, r'AgeCategory', 'rank'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'AgeCategory', 'id'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
