// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_meta.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageMeta extends PageMeta {
  @override
  final int page;
  @override
  final int size;
  @override
  final int totalElements;
  @override
  final int totalPages;

  factory _$PageMeta([void Function(PageMetaBuilder)? updates]) =>
      (PageMetaBuilder()..update(updates))._build();

  _$PageMeta._(
      {required this.page,
      required this.size,
      required this.totalElements,
      required this.totalPages})
      : super._();
  @override
  PageMeta rebuild(void Function(PageMetaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageMetaBuilder toBuilder() => PageMetaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageMeta &&
        page == other.page &&
        size == other.size &&
        totalElements == other.totalElements &&
        totalPages == other.totalPages;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jc(_$hash, totalElements.hashCode);
    _$hash = $jc(_$hash, totalPages.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PageMeta')
          ..add('page', page)
          ..add('size', size)
          ..add('totalElements', totalElements)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class PageMetaBuilder implements Builder<PageMeta, PageMetaBuilder> {
  _$PageMeta? _$v;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  int? _totalElements;
  int? get totalElements => _$this._totalElements;
  set totalElements(int? totalElements) =>
      _$this._totalElements = totalElements;

  int? _totalPages;
  int? get totalPages => _$this._totalPages;
  set totalPages(int? totalPages) => _$this._totalPages = totalPages;

  PageMetaBuilder() {
    PageMeta._defaults(this);
  }

  PageMetaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _page = $v.page;
      _size = $v.size;
      _totalElements = $v.totalElements;
      _totalPages = $v.totalPages;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PageMeta other) {
    _$v = other as _$PageMeta;
  }

  @override
  void update(void Function(PageMetaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageMeta build() => _build();

  _$PageMeta _build() {
    final _$result = _$v ??
        _$PageMeta._(
          page:
              BuiltValueNullFieldError.checkNotNull(page, r'PageMeta', 'page'),
          size:
              BuiltValueNullFieldError.checkNotNull(size, r'PageMeta', 'size'),
          totalElements: BuiltValueNullFieldError.checkNotNull(
              totalElements, r'PageMeta', 'totalElements'),
          totalPages: BuiltValueNullFieldError.checkNotNull(
              totalPages, r'PageMeta', 'totalPages'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
