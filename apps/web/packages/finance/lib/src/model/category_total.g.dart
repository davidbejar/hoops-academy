// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_total.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CategoryTotal extends CategoryTotal {
  @override
  final ExpenseCategory category;
  @override
  final int totalMinor;

  factory _$CategoryTotal([void Function(CategoryTotalBuilder)? updates]) =>
      (CategoryTotalBuilder()..update(updates))._build();

  _$CategoryTotal._({required this.category, required this.totalMinor})
      : super._();
  @override
  CategoryTotal rebuild(void Function(CategoryTotalBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategoryTotalBuilder toBuilder() => CategoryTotalBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CategoryTotal &&
        category == other.category &&
        totalMinor == other.totalMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, totalMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CategoryTotal')
          ..add('category', category)
          ..add('totalMinor', totalMinor))
        .toString();
  }
}

class CategoryTotalBuilder
    implements Builder<CategoryTotal, CategoryTotalBuilder> {
  _$CategoryTotal? _$v;

  ExpenseCategory? _category;
  ExpenseCategory? get category => _$this._category;
  set category(ExpenseCategory? category) => _$this._category = category;

  int? _totalMinor;
  int? get totalMinor => _$this._totalMinor;
  set totalMinor(int? totalMinor) => _$this._totalMinor = totalMinor;

  CategoryTotalBuilder() {
    CategoryTotal._defaults(this);
  }

  CategoryTotalBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _category = $v.category;
      _totalMinor = $v.totalMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CategoryTotal other) {
    _$v = other as _$CategoryTotal;
  }

  @override
  void update(void Function(CategoryTotalBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CategoryTotal build() => _build();

  _$CategoryTotal _build() {
    final _$result = _$v ??
        _$CategoryTotal._(
          category: BuiltValueNullFieldError.checkNotNull(
              category, r'CategoryTotal', 'category'),
          totalMinor: BuiltValueNullFieldError.checkNotNull(
              totalMinor, r'CategoryTotal', 'totalMinor'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
