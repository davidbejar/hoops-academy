// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_audit_event_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlatformAuditEventPage extends PlatformAuditEventPage {
  @override
  final BuiltList<PlatformAuditEvent> items;
  @override
  final PageMeta page;

  factory _$PlatformAuditEventPage(
          [void Function(PlatformAuditEventPageBuilder)? updates]) =>
      (PlatformAuditEventPageBuilder()..update(updates))._build();

  _$PlatformAuditEventPage._({required this.items, required this.page})
      : super._();
  @override
  PlatformAuditEventPage rebuild(
          void Function(PlatformAuditEventPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformAuditEventPageBuilder toBuilder() =>
      PlatformAuditEventPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformAuditEventPage &&
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
    return (newBuiltValueToStringHelper(r'PlatformAuditEventPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class PlatformAuditEventPageBuilder
    implements Builder<PlatformAuditEventPage, PlatformAuditEventPageBuilder> {
  _$PlatformAuditEventPage? _$v;

  ListBuilder<PlatformAuditEvent>? _items;
  ListBuilder<PlatformAuditEvent> get items =>
      _$this._items ??= ListBuilder<PlatformAuditEvent>();
  set items(ListBuilder<PlatformAuditEvent>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  PlatformAuditEventPageBuilder() {
    PlatformAuditEventPage._defaults(this);
  }

  PlatformAuditEventPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformAuditEventPage other) {
    _$v = other as _$PlatformAuditEventPage;
  }

  @override
  void update(void Function(PlatformAuditEventPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformAuditEventPage build() => _build();

  _$PlatformAuditEventPage _build() {
    _$PlatformAuditEventPage _$result;
    try {
      _$result = _$v ??
          _$PlatformAuditEventPage._(
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
            r'PlatformAuditEventPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
