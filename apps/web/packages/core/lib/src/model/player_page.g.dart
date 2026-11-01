// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerPage extends PlayerPage {
  @override
  final BuiltList<Player> items;
  @override
  final PageMeta page;

  factory _$PlayerPage([void Function(PlayerPageBuilder)? updates]) =>
      (PlayerPageBuilder()..update(updates))._build();

  _$PlayerPage._({required this.items, required this.page}) : super._();
  @override
  PlayerPage rebuild(void Function(PlayerPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerPageBuilder toBuilder() => PlayerPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'PlayerPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlayerPageBuilder implements Builder<PlayerPage, PlayerPageBuilder> {
  _$PlayerPage? _$v;

  ListBuilder<Player>? _items;
  ListBuilder<Player> get items => _$this._items ??= ListBuilder<Player>();
  set items(ListBuilder<Player>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlayerPageBuilder() {
    PlayerPage._defaults(this);
  }

  PlayerPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerPage other) {
    _$v = other as _$PlayerPage;
  }

  @override
  void update(void Function(PlayerPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerPage build() => _build();

  _$PlayerPage _build() {
    _$PlayerPage _$result;
    try {
      _$result = _$v ??
          _$PlayerPage._(
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
            r'PlayerPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
