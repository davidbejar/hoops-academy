// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AgeCategory extends AgeCategory {
  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final int? maxAge;
  @override
  final int rank;

  factory _$AgeCategory([void Function(AgeCategoryBuilder)? updates]) =>
      (AgeCategoryBuilder()..update(updates))._build();

  _$AgeCategory._(
      {required this.id,
      required this.code,
      required this.name,
      this.maxAge,
      required this.rank})
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
        id == other.id &&
        code == other.code &&
        name == other.name &&
        maxAge == other.maxAge &&
        rank == other.rank;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, maxAge.hashCode);
    _$hash = $jc(_$hash, rank.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AgeCategory')
          ..add('id', id)
          ..add('code', code)
          ..add('name', name)
          ..add('maxAge', maxAge)
          ..add('rank', rank))
        .toString();
  }
}

class AgeCategoryBuilder
    implements
        Builder<AgeCategory, AgeCategoryBuilder>,
        AgeCategoryInputBuilder {
  _$AgeCategory? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  String? _code;
  String? get code => _$this._code;
  set code(covariant String? code) => _$this._code = code;

  String? _name;
  String? get name => _$this._name;
  set name(covariant String? name) => _$this._name = name;

  int? _maxAge;
  int? get maxAge => _$this._maxAge;
  set maxAge(covariant int? maxAge) => _$this._maxAge = maxAge;

  int? _rank;
  int? get rank => _$this._rank;
  set rank(covariant int? rank) => _$this._rank = rank;

  AgeCategoryBuilder() {
    AgeCategory._defaults(this);
  }

  AgeCategoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _code = $v.code;
      _name = $v.name;
      _maxAge = $v.maxAge;
      _rank = $v.rank;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant AgeCategory other) {
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
          id: BuiltValueNullFieldError.checkNotNull(id, r'AgeCategory', 'id'),
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'AgeCategory', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'AgeCategory', 'name'),
          maxAge: maxAge,
          rank: BuiltValueNullFieldError.checkNotNull(
              rank, r'AgeCategory', 'rank'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
