// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchPage extends MatchPage {
  @override
  final BuiltList<Match> items;
  @override
  final PageMeta page;

  factory _$MatchPage([void Function(MatchPageBuilder)? updates]) =>
      (MatchPageBuilder()..update(updates))._build();

  _$MatchPage._({required this.items, required this.page}) : super._();
  @override
  MatchPage rebuild(void Function(MatchPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchPageBuilder toBuilder() => MatchPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'MatchPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class MatchPageBuilder implements Builder<MatchPage, MatchPageBuilder> {
  _$MatchPage? _$v;

  ListBuilder<Match>? _items;
  ListBuilder<Match> get items => _$this._items ??= ListBuilder<Match>();
  set items(ListBuilder<Match>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  MatchPageBuilder() {
    MatchPage._defaults(this);
  }

  MatchPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchPage other) {
    _$v = other as _$MatchPage;
  }

  @override
  void update(void Function(MatchPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchPage build() => _build();

  _$MatchPage _build() {
    _$MatchPage _$result;
    try {
      _$result = _$v ??
          _$MatchPage._(
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
            r'MatchPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
