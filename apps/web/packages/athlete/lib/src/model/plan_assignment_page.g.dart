// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_assignment_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanAssignmentPage extends PlanAssignmentPage {
  @override
  final BuiltList<PlanAssignment> items;
  @override
  final PageMeta page;

  factory _$PlanAssignmentPage(
          [void Function(PlanAssignmentPageBuilder)? updates]) =>
      (PlanAssignmentPageBuilder()..update(updates))._build();

  _$PlanAssignmentPage._({required this.items, required this.page}) : super._();
  @override
  PlanAssignmentPage rebuild(
          void Function(PlanAssignmentPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanAssignmentPageBuilder toBuilder() =>
      PlanAssignmentPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanAssignmentPage &&
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
    return (newBuiltValueToStringHelper(r'PlanAssignmentPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlanAssignmentPageBuilder
    implements Builder<PlanAssignmentPage, PlanAssignmentPageBuilder> {
  _$PlanAssignmentPage? _$v;

  ListBuilder<PlanAssignment>? _items;
  ListBuilder<PlanAssignment> get items =>
      _$this._items ??= ListBuilder<PlanAssignment>();
  set items(ListBuilder<PlanAssignment>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlanAssignmentPageBuilder() {
    PlanAssignmentPage._defaults(this);
  }

  PlanAssignmentPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanAssignmentPage other) {
    _$v = other as _$PlanAssignmentPage;
  }

  @override
  void update(void Function(PlanAssignmentPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanAssignmentPage build() => _build();

  _$PlanAssignmentPage _build() {
    _$PlanAssignmentPage _$result;
    try {
      _$result = _$v ??
          _$PlanAssignmentPage._(
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
            r'PlanAssignmentPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
