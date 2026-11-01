// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_result_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestResultPage extends PhysicalTestResultPage {
  @override
  final BuiltList<PhysicalTestResult> items;
  @override
  final PageMeta page;

  factory _$PhysicalTestResultPage(
          [void Function(PhysicalTestResultPageBuilder)? updates]) =>
      (PhysicalTestResultPageBuilder()..update(updates))._build();

  _$PhysicalTestResultPage._({required this.items, required this.page})
      : super._();
  @override
  PhysicalTestResultPage rebuild(
          void Function(PhysicalTestResultPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhysicalTestResultPageBuilder toBuilder() =>
      PhysicalTestResultPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhysicalTestResultPage &&
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
    return (newBuiltValueToStringHelper(r'PhysicalTestResultPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PhysicalTestResultPageBuilder
    implements Builder<PhysicalTestResultPage, PhysicalTestResultPageBuilder> {
  _$PhysicalTestResultPage? _$v;

  ListBuilder<PhysicalTestResult>? _items;
  ListBuilder<PhysicalTestResult> get items =>
      _$this._items ??= ListBuilder<PhysicalTestResult>();
  set items(ListBuilder<PhysicalTestResult>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PhysicalTestResultPageBuilder() {
    PhysicalTestResultPage._defaults(this);
  }

  PhysicalTestResultPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhysicalTestResultPage other) {
    _$v = other as _$PhysicalTestResultPage;
  }

  @override
  void update(void Function(PhysicalTestResultPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhysicalTestResultPage build() => _build();

  _$PhysicalTestResultPage _build() {
    _$PhysicalTestResultPage _$result;
    try {
      _$result = _$v ??
          _$PhysicalTestResultPage._(
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
            r'PhysicalTestResultPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
