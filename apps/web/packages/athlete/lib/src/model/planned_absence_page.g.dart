// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_absence_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlannedAbsencePage extends PlannedAbsencePage {
  @override
  final BuiltList<PlannedAbsence> items;
  @override
  final PageMeta page;

  factory _$PlannedAbsencePage(
          [void Function(PlannedAbsencePageBuilder)? updates]) =>
      (PlannedAbsencePageBuilder()..update(updates))._build();

  _$PlannedAbsencePage._({required this.items, required this.page}) : super._();
  @override
  PlannedAbsencePage rebuild(
          void Function(PlannedAbsencePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlannedAbsencePageBuilder toBuilder() =>
      PlannedAbsencePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlannedAbsencePage &&
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
    return (newBuiltValueToStringHelper(r'PlannedAbsencePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlannedAbsencePageBuilder
    implements Builder<PlannedAbsencePage, PlannedAbsencePageBuilder> {
  _$PlannedAbsencePage? _$v;

  ListBuilder<PlannedAbsence>? _items;
  ListBuilder<PlannedAbsence> get items =>
      _$this._items ??= ListBuilder<PlannedAbsence>();
  set items(ListBuilder<PlannedAbsence>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlannedAbsencePageBuilder() {
    PlannedAbsencePage._defaults(this);
  }

  PlannedAbsencePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlannedAbsencePage other) {
    _$v = other as _$PlannedAbsencePage;
  }

  @override
  void update(void Function(PlannedAbsencePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlannedAbsencePage build() => _build();

  _$PlannedAbsencePage _build() {
    _$PlannedAbsencePage _$result;
    try {
      _$result = _$v ??
          _$PlannedAbsencePage._(
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
            r'PlannedAbsencePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
