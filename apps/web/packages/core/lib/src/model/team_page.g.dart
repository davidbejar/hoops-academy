// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TeamPage extends TeamPage {
  @override
  final BuiltList<Team> items;
  @override
  final PageMeta page;

  factory _$TeamPage([void Function(TeamPageBuilder)? updates]) =>
      (TeamPageBuilder()..update(updates))._build();

  _$TeamPage._({required this.items, required this.page}) : super._();
  @override
  TeamPage rebuild(void Function(TeamPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamPageBuilder toBuilder() => TeamPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamPage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'TeamPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class TeamPageBuilder implements Builder<TeamPage, TeamPageBuilder> {
  _$TeamPage? _$v;

  ListBuilder<Team>? _items;
  ListBuilder<Team> get items => _$this._items ??= ListBuilder<Team>();
  set items(ListBuilder<Team>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  TeamPageBuilder() {
    TeamPage._defaults(this);
  }

  TeamPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamPage other) {
    _$v = other as _$TeamPage;
  }

  @override
  void update(void Function(TeamPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TeamPage build() => _build();

  _$TeamPage _build() {
    _$TeamPage _$result;
    try {
      _$result = _$v ??
          _$TeamPage._(
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
            r'TeamPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
