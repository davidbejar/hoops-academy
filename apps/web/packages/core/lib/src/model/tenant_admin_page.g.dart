// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_admin_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantAdminPage extends TenantAdminPage {
  @override
  final BuiltList<TenantAdmin> items;
  @override
  final PageMeta page;

  factory _$TenantAdminPage([void Function(TenantAdminPageBuilder)? updates]) =>
      (TenantAdminPageBuilder()..update(updates))._build();

  _$TenantAdminPage._({required this.items, required this.page}) : super._();
  @override
  TenantAdminPage rebuild(void Function(TenantAdminPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantAdminPageBuilder toBuilder() => TenantAdminPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantAdminPage &&
        items == other.items &&
        page == other.page;
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
    return (newBuiltValueToStringHelper(r'TenantAdminPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class TenantAdminPageBuilder
    implements Builder<TenantAdminPage, TenantAdminPageBuilder> {
  _$TenantAdminPage? _$v;

  ListBuilder<TenantAdmin>? _items;
  ListBuilder<TenantAdmin> get items =>
      _$this._items ??= ListBuilder<TenantAdmin>();
  set items(ListBuilder<TenantAdmin>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  TenantAdminPageBuilder() {
    TenantAdminPage._defaults(this);
  }

  TenantAdminPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantAdminPage other) {
    _$v = other as _$TenantAdminPage;
  }

  @override
  void update(void Function(TenantAdminPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantAdminPage build() => _build();

  _$TenantAdminPage _build() {
    _$TenantAdminPage _$result;
    try {
      _$result = _$v ??
          _$TenantAdminPage._(
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
            r'TenantAdminPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
