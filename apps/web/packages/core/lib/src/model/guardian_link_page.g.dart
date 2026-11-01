// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guardian_link_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GuardianLinkPage extends GuardianLinkPage {
  @override
  final BuiltList<GuardianLink> items;
  @override
  final PageMeta page;

  factory _$GuardianLinkPage(
          [void Function(GuardianLinkPageBuilder)? updates]) =>
      (GuardianLinkPageBuilder()..update(updates))._build();

  _$GuardianLinkPage._({required this.items, required this.page}) : super._();
  @override
  GuardianLinkPage rebuild(void Function(GuardianLinkPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GuardianLinkPageBuilder toBuilder() =>
      GuardianLinkPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GuardianLinkPage &&
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
    return (newBuiltValueToStringHelper(r'GuardianLinkPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class GuardianLinkPageBuilder
    implements Builder<GuardianLinkPage, GuardianLinkPageBuilder> {
  _$GuardianLinkPage? _$v;

  ListBuilder<GuardianLink>? _items;
  ListBuilder<GuardianLink> get items =>
      _$this._items ??= ListBuilder<GuardianLink>();
  set items(ListBuilder<GuardianLink>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  GuardianLinkPageBuilder() {
    GuardianLinkPage._defaults(this);
  }

  GuardianLinkPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GuardianLinkPage other) {
    _$v = other as _$GuardianLinkPage;
  }

  @override
  void update(void Function(GuardianLinkPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GuardianLinkPage build() => _build();

  _$GuardianLinkPage _build() {
    _$GuardianLinkPage _$result;
    try {
      _$result = _$v ??
          _$GuardianLinkPage._(
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
            r'GuardianLinkPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
