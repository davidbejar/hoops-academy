// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DuePage extends DuePage {
  @override
  final BuiltList<Due> items;
  @override
  final PageMeta page;

  factory _$DuePage([void Function(DuePageBuilder)? updates]) =>
      (DuePageBuilder()..update(updates))._build();

  _$DuePage._({required this.items, required this.page}) : super._();
  @override
  DuePage rebuild(void Function(DuePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DuePageBuilder toBuilder() => DuePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DuePage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'DuePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class DuePageBuilder implements Builder<DuePage, DuePageBuilder> {
  _$DuePage? _$v;

  ListBuilder<Due>? _items;
  ListBuilder<Due> get items => _$this._items ??= ListBuilder<Due>();
  set items(ListBuilder<Due>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  DuePageBuilder() {
    DuePage._defaults(this);
  }

  DuePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DuePage other) {
    _$v = other as _$DuePage;
  }

  @override
  void update(void Function(DuePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DuePage build() => _build();

  _$DuePage _build() {
    _$DuePage _$result;
    try {
      _$result = _$v ??
          _$DuePage._(
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
            r'DuePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
