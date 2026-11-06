// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'copy_plan_items_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CopyPlanItemsRequest extends CopyPlanItemsRequest {
  @override
  final BuiltList<PlanItemRef> items;

  factory _$CopyPlanItemsRequest(
          [void Function(CopyPlanItemsRequestBuilder)? updates]) =>
      (CopyPlanItemsRequestBuilder()..update(updates))._build();

  _$CopyPlanItemsRequest._({required this.items}) : super._();
  @override
  CopyPlanItemsRequest rebuild(
          void Function(CopyPlanItemsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CopyPlanItemsRequestBuilder toBuilder() =>
      CopyPlanItemsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CopyPlanItemsRequest && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CopyPlanItemsRequest')
          ..add('items', items))
        .toString();
  }
}

class CopyPlanItemsRequestBuilder
    implements Builder<CopyPlanItemsRequest, CopyPlanItemsRequestBuilder> {
  _$CopyPlanItemsRequest? _$v;

  ListBuilder<PlanItemRef>? _items;
  ListBuilder<PlanItemRef> get items =>
      _$this._items ??= ListBuilder<PlanItemRef>();
  set items(ListBuilder<PlanItemRef>? items) => _$this._items = items;

  CopyPlanItemsRequestBuilder() {
    CopyPlanItemsRequest._defaults(this);
  }

  CopyPlanItemsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CopyPlanItemsRequest other) {
    _$v = other as _$CopyPlanItemsRequest;
  }

  @override
  void update(void Function(CopyPlanItemsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CopyPlanItemsRequest build() => _build();

  _$CopyPlanItemsRequest _build() {
    _$CopyPlanItemsRequest _$result;
    try {
      _$result = _$v ??
          _$CopyPlanItemsRequest._(
            items: items.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CopyPlanItemsRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
