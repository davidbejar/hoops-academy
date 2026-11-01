// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantPage extends TenantPage {
  @override
  final BuiltList<Tenant> items;
  @override
  final PageMeta page;

  factory _$TenantPage([void Function(TenantPageBuilder)? updates]) =>
      (TenantPageBuilder()..update(updates))._build();

  _$TenantPage._({required this.items, required this.page}) : super._();
  @override
  TenantPage rebuild(void Function(TenantPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantPageBuilder toBuilder() => TenantPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'TenantPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class TenantPageBuilder implements Builder<TenantPage, TenantPageBuilder> {
  _$TenantPage? _$v;

  ListBuilder<Tenant>? _items;
  ListBuilder<Tenant> get items => _$this._items ??= ListBuilder<Tenant>();
  set items(ListBuilder<Tenant>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  TenantPageBuilder() {
    TenantPage._defaults(this);
  }

  TenantPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantPage other) {
    _$v = other as _$TenantPage;
  }

  @override
  void update(void Function(TenantPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantPage build() => _build();

  _$TenantPage _build() {
    _$TenantPage _$result;
    try {
      _$result = _$v ??
          _$TenantPage._(
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
            r'TenantPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
