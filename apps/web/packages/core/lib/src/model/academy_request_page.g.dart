// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_request_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcademyRequestPage extends AcademyRequestPage {
  @override
  final BuiltList<AcademyRequest> items;
  @override
  final PageMeta page;

  factory _$AcademyRequestPage(
          [void Function(AcademyRequestPageBuilder)? updates]) =>
      (AcademyRequestPageBuilder()..update(updates))._build();

  _$AcademyRequestPage._({required this.items, required this.page}) : super._();
  @override
  AcademyRequestPage rebuild(
          void Function(AcademyRequestPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcademyRequestPageBuilder toBuilder() =>
      AcademyRequestPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcademyRequestPage &&
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
    return (newBuiltValueToStringHelper(r'AcademyRequestPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class AcademyRequestPageBuilder
    implements Builder<AcademyRequestPage, AcademyRequestPageBuilder> {
  _$AcademyRequestPage? _$v;

  ListBuilder<AcademyRequest>? _items;
  ListBuilder<AcademyRequest> get items =>
      _$this._items ??= ListBuilder<AcademyRequest>();
  set items(ListBuilder<AcademyRequest>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  AcademyRequestPageBuilder() {
    AcademyRequestPage._defaults(this);
  }

  AcademyRequestPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcademyRequestPage other) {
    _$v = other as _$AcademyRequestPage;
  }

  @override
  void update(void Function(AcademyRequestPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcademyRequestPage build() => _build();

  _$AcademyRequestPage _build() {
    _$AcademyRequestPage _$result;
    try {
      _$result = _$v ??
          _$AcademyRequestPage._(
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
            r'AcademyRequestPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
