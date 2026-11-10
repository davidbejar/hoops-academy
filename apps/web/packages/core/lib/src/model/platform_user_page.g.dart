// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_user_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlatformUserPage extends PlatformUserPage {
  @override
  final BuiltList<PlatformUser> items;
  @override
  final PageMeta page;

  factory _$PlatformUserPage(
          [void Function(PlatformUserPageBuilder)? updates]) =>
      (PlatformUserPageBuilder()..update(updates))._build();

  _$PlatformUserPage._({required this.items, required this.page}) : super._();
  @override
  PlatformUserPage rebuild(void Function(PlatformUserPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformUserPageBuilder toBuilder() =>
      PlatformUserPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformUserPage &&
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
    return (newBuiltValueToStringHelper(r'PlatformUserPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlatformUserPageBuilder
    implements Builder<PlatformUserPage, PlatformUserPageBuilder> {
  _$PlatformUserPage? _$v;

  ListBuilder<PlatformUser>? _items;
  ListBuilder<PlatformUser> get items =>
      _$this._items ??= ListBuilder<PlatformUser>();
  set items(ListBuilder<PlatformUser>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlatformUserPageBuilder() {
    PlatformUserPage._defaults(this);
  }

  PlatformUserPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformUserPage other) {
    _$v = other as _$PlatformUserPage;
  }

  @override
  void update(void Function(PlatformUserPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformUserPage build() => _build();

  _$PlatformUserPage _build() {
    _$PlatformUserPage _$result;
    try {
      _$result = _$v ??
          _$PlatformUserPage._(
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
            r'PlatformUserPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
