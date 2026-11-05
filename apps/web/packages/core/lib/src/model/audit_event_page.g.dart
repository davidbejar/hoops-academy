// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_event_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditEventPage extends AuditEventPage {
  @override
  final BuiltList<AuditEvent> items;
  @override
  final PageMeta page;

  factory _$AuditEventPage([void Function(AuditEventPageBuilder)? updates]) =>
      (AuditEventPageBuilder()..update(updates))._build();

  _$AuditEventPage._({required this.items, required this.page}) : super._();
  @override
  AuditEventPage rebuild(void Function(AuditEventPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuditEventPageBuilder toBuilder() => AuditEventPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditEventPage &&
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
    return (newBuiltValueToStringHelper(r'AuditEventPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class AuditEventPageBuilder
    implements Builder<AuditEventPage, AuditEventPageBuilder> {
  _$AuditEventPage? _$v;

  ListBuilder<AuditEvent>? _items;
  ListBuilder<AuditEvent> get items =>
      _$this._items ??= ListBuilder<AuditEvent>();
  set items(ListBuilder<AuditEvent>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  AuditEventPageBuilder() {
    AuditEventPage._defaults(this);
  }

  AuditEventPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditEventPage other) {
    _$v = other as _$AuditEventPage;
  }

  @override
  void update(void Function(AuditEventPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditEventPage build() => _build();

  _$AuditEventPage _build() {
    _$AuditEventPage _$result;
    try {
      _$result = _$v ??
          _$AuditEventPage._(
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
            r'AuditEventPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
