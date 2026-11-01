// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injury_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InjuryPage extends InjuryPage {
  @override
  final BuiltList<Injury> items;
  @override
  final PageMeta page;

  factory _$InjuryPage([void Function(InjuryPageBuilder)? updates]) =>
      (InjuryPageBuilder()..update(updates))._build();

  _$InjuryPage._({required this.items, required this.page}) : super._();
  @override
  InjuryPage rebuild(void Function(InjuryPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InjuryPageBuilder toBuilder() => InjuryPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InjuryPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'InjuryPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class InjuryPageBuilder implements Builder<InjuryPage, InjuryPageBuilder> {
  _$InjuryPage? _$v;

  ListBuilder<Injury>? _items;
  ListBuilder<Injury> get items => _$this._items ??= ListBuilder<Injury>();
  set items(ListBuilder<Injury>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  InjuryPageBuilder() {
    InjuryPage._defaults(this);
  }

  InjuryPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InjuryPage other) {
    _$v = other as _$InjuryPage;
  }

  @override
  void update(void Function(InjuryPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InjuryPage build() => _build();

  _$InjuryPage _build() {
    _$InjuryPage _$result;
    try {
      _$result = _$v ??
          _$InjuryPage._(
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
            r'InjuryPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
