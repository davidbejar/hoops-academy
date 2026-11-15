// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_due_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerDuePage extends PlayerDuePage {
  @override
  final BuiltList<PlayerDue> items;
  @override
  final PageMeta page;

  factory _$PlayerDuePage([void Function(PlayerDuePageBuilder)? updates]) =>
      (PlayerDuePageBuilder()..update(updates))._build();

  _$PlayerDuePage._({required this.items, required this.page}) : super._();
  @override
  PlayerDuePage rebuild(void Function(PlayerDuePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerDuePageBuilder toBuilder() => PlayerDuePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerDuePage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'PlayerDuePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlayerDuePageBuilder
    implements Builder<PlayerDuePage, PlayerDuePageBuilder> {
  _$PlayerDuePage? _$v;

  ListBuilder<PlayerDue>? _items;
  ListBuilder<PlayerDue> get items =>
      _$this._items ??= ListBuilder<PlayerDue>();
  set items(ListBuilder<PlayerDue>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlayerDuePageBuilder() {
    PlayerDuePage._defaults(this);
  }

  PlayerDuePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerDuePage other) {
    _$v = other as _$PlayerDuePage;
  }

  @override
  void update(void Function(PlayerDuePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerDuePage build() => _build();

  _$PlayerDuePage _build() {
    _$PlayerDuePage _$result;
    try {
      _$result = _$v ??
          _$PlayerDuePage._(
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
            r'PlayerDuePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
