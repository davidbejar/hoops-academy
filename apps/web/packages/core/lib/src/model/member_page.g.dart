// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MemberPage extends MemberPage {
  @override
  final BuiltList<Member> items;
  @override
  final PageMeta page;

  factory _$MemberPage([void Function(MemberPageBuilder)? updates]) =>
      (MemberPageBuilder()..update(updates))._build();

  _$MemberPage._({required this.items, required this.page}) : super._();
  @override
  MemberPage rebuild(void Function(MemberPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MemberPageBuilder toBuilder() => MemberPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MemberPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'MemberPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class MemberPageBuilder implements Builder<MemberPage, MemberPageBuilder> {
  _$MemberPage? _$v;

  ListBuilder<Member>? _items;
  ListBuilder<Member> get items => _$this._items ??= ListBuilder<Member>();
  set items(ListBuilder<Member>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  MemberPageBuilder() {
    MemberPage._defaults(this);
  }

  MemberPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MemberPage other) {
    _$v = other as _$MemberPage;
  }

  @override
  void update(void Function(MemberPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MemberPage build() => _build();

  _$MemberPage _build() {
    _$MemberPage _$result;
    try {
      _$result = _$v ??
          _$MemberPage._(
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
            r'MemberPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
