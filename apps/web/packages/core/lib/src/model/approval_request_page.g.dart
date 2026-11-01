// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_request_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ApprovalRequestPage extends ApprovalRequestPage {
  @override
  final BuiltList<ApprovalRequest> items;
  @override
  final PageMeta page;

  factory _$ApprovalRequestPage(
          [void Function(ApprovalRequestPageBuilder)? updates]) =>
      (ApprovalRequestPageBuilder()..update(updates))._build();

  _$ApprovalRequestPage._({required this.items, required this.page})
      : super._();
  @override
  ApprovalRequestPage rebuild(
          void Function(ApprovalRequestPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApprovalRequestPageBuilder toBuilder() =>
      ApprovalRequestPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApprovalRequestPage &&
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
    return (newBuiltValueToStringHelper(r'ApprovalRequestPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class ApprovalRequestPageBuilder
    implements Builder<ApprovalRequestPage, ApprovalRequestPageBuilder> {
  _$ApprovalRequestPage? _$v;

  ListBuilder<ApprovalRequest>? _items;
  ListBuilder<ApprovalRequest> get items =>
      _$this._items ??= ListBuilder<ApprovalRequest>();
  set items(ListBuilder<ApprovalRequest>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  ApprovalRequestPageBuilder() {
    ApprovalRequestPage._defaults(this);
  }

  ApprovalRequestPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApprovalRequestPage other) {
    _$v = other as _$ApprovalRequestPage;
  }

  @override
  void update(void Function(ApprovalRequestPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ApprovalRequestPage build() => _build();

  _$ApprovalRequestPage _build() {
    _$ApprovalRequestPage _$result;
    try {
      _$result = _$v ??
          _$ApprovalRequestPage._(
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
            r'ApprovalRequestPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
