// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_plan_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FeePlanPage extends FeePlanPage {
  @override
  final BuiltList<FeePlan> items;
  @override
  final PageMeta page;

  factory _$FeePlanPage([void Function(FeePlanPageBuilder)? updates]) =>
      (FeePlanPageBuilder()..update(updates))._build();

  _$FeePlanPage._({required this.items, required this.page}) : super._();
  @override
  FeePlanPage rebuild(void Function(FeePlanPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FeePlanPageBuilder toBuilder() => FeePlanPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FeePlanPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'FeePlanPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class FeePlanPageBuilder implements Builder<FeePlanPage, FeePlanPageBuilder> {
  _$FeePlanPage? _$v;

  ListBuilder<FeePlan>? _items;
  ListBuilder<FeePlan> get items => _$this._items ??= ListBuilder<FeePlan>();
  set items(ListBuilder<FeePlan>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  FeePlanPageBuilder() {
    FeePlanPage._defaults(this);
  }

  FeePlanPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FeePlanPage other) {
    _$v = other as _$FeePlanPage;
  }

  @override
  void update(void Function(FeePlanPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FeePlanPage build() => _build();

  _$FeePlanPage _build() {
    _$FeePlanPage _$result;
    try {
      _$result = _$v ??
          _$FeePlanPage._(
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
            r'FeePlanPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
