// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpensePage extends ExpensePage {
  @override
  final BuiltList<Expense> items;
  @override
  final PageMeta page;

  factory _$ExpensePage([void Function(ExpensePageBuilder)? updates]) =>
      (ExpensePageBuilder()..update(updates))._build();

  _$ExpensePage._({required this.items, required this.page}) : super._();
  @override
  ExpensePage rebuild(void Function(ExpensePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpensePageBuilder toBuilder() => ExpensePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpensePage && items == other.items && page == other.page;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpensePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class ExpensePageBuilder implements Builder<ExpensePage, ExpensePageBuilder> {
  _$ExpensePage? _$v;

  ListBuilder<Expense>? _items;
  ListBuilder<Expense> get items => _$this._items ??= ListBuilder<Expense>();
  set items(ListBuilder<Expense>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  ExpensePageBuilder() {
    ExpensePage._defaults(this);
  }

  ExpensePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpensePage other) {
    _$v = other as _$ExpensePage;
  }

  @override
  void update(void Function(ExpensePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpensePage build() => _build();

  _$ExpensePage _build() {
    _$ExpensePage _$result;
    try {
      _$result = _$v ??
          _$ExpensePage._(
            items: items.build(),
            page: page.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ExpensePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
