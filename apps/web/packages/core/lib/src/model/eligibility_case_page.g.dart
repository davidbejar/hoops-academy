// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eligibility_case_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EligibilityCasePage extends EligibilityCasePage {
  @override
  final BuiltList<EligibilityCase> items;
  @override
  final PageMeta page;

  factory _$EligibilityCasePage(
          [void Function(EligibilityCasePageBuilder)? updates]) =>
      (EligibilityCasePageBuilder()..update(updates))._build();

  _$EligibilityCasePage._({required this.items, required this.page})
      : super._();
  @override
  EligibilityCasePage rebuild(
          void Function(EligibilityCasePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EligibilityCasePageBuilder toBuilder() =>
      EligibilityCasePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EligibilityCasePage &&
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
    return (newBuiltValueToStringHelper(r'EligibilityCasePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class EligibilityCasePageBuilder
    implements Builder<EligibilityCasePage, EligibilityCasePageBuilder> {
  _$EligibilityCasePage? _$v;

  ListBuilder<EligibilityCase>? _items;
  ListBuilder<EligibilityCase> get items =>
      _$this._items ??= ListBuilder<EligibilityCase>();
  set items(ListBuilder<EligibilityCase>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  EligibilityCasePageBuilder() {
    EligibilityCasePage._defaults(this);
  }

  EligibilityCasePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EligibilityCasePage other) {
    _$v = other as _$EligibilityCasePage;
  }

  @override
  void update(void Function(EligibilityCasePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EligibilityCasePage build() => _build();

  _$EligibilityCasePage _build() {
    _$EligibilityCasePage _$result;
    try {
      _$result = _$v ??
          _$EligibilityCasePage._(
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
            r'EligibilityCasePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
