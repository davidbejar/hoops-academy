// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_completion_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanCompletionPage extends PlanCompletionPage {
  @override
  final BuiltList<PlanCompletion> items;
  @override
  final PageMeta page;

  factory _$PlanCompletionPage(
          [void Function(PlanCompletionPageBuilder)? updates]) =>
      (PlanCompletionPageBuilder()..update(updates))._build();

  _$PlanCompletionPage._({required this.items, required this.page}) : super._();
  @override
  PlanCompletionPage rebuild(
          void Function(PlanCompletionPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanCompletionPageBuilder toBuilder() =>
      PlanCompletionPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanCompletionPage &&
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
    return (newBuiltValueToStringHelper(r'PlanCompletionPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlanCompletionPageBuilder
    implements Builder<PlanCompletionPage, PlanCompletionPageBuilder> {
  _$PlanCompletionPage? _$v;

  ListBuilder<PlanCompletion>? _items;
  ListBuilder<PlanCompletion> get items =>
      _$this._items ??= ListBuilder<PlanCompletion>();
  set items(ListBuilder<PlanCompletion>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlanCompletionPageBuilder() {
    PlanCompletionPage._defaults(this);
  }

  PlanCompletionPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanCompletionPage other) {
    _$v = other as _$PlanCompletionPage;
  }

  @override
  void update(void Function(PlanCompletionPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanCompletionPage build() => _build();

  _$PlanCompletionPage _build() {
    _$PlanCompletionPage _$result;
    try {
      _$result = _$v ??
          _$PlanCompletionPage._(
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
            r'PlanCompletionPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
