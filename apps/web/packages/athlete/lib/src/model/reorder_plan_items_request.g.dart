// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_plan_items_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReorderPlanItemsRequest extends ReorderPlanItemsRequest {
  @override
  final BuiltSet<String> itemIds;

  factory _$ReorderPlanItemsRequest(
          [void Function(ReorderPlanItemsRequestBuilder)? updates]) =>
      (ReorderPlanItemsRequestBuilder()..update(updates))._build();

  _$ReorderPlanItemsRequest._({required this.itemIds}) : super._();
  @override
  ReorderPlanItemsRequest rebuild(
          void Function(ReorderPlanItemsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReorderPlanItemsRequestBuilder toBuilder() =>
      ReorderPlanItemsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReorderPlanItemsRequest && itemIds == other.itemIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, itemIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReorderPlanItemsRequest')
          ..add('itemIds', itemIds))
        .toString();
  }
}

class ReorderPlanItemsRequestBuilder
    implements
        Builder<ReorderPlanItemsRequest, ReorderPlanItemsRequestBuilder> {
  _$ReorderPlanItemsRequest? _$v;

  SetBuilder<String>? _itemIds;
  SetBuilder<String> get itemIds => _$this._itemIds ??= SetBuilder<String>();
  set itemIds(SetBuilder<String>? itemIds) => _$this._itemIds = itemIds;

  ReorderPlanItemsRequestBuilder() {
    ReorderPlanItemsRequest._defaults(this);
  }

  ReorderPlanItemsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _itemIds = $v.itemIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReorderPlanItemsRequest other) {
    _$v = other as _$ReorderPlanItemsRequest;
  }

  @override
  void update(void Function(ReorderPlanItemsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReorderPlanItemsRequest build() => _build();

  _$ReorderPlanItemsRequest _build() {
    _$ReorderPlanItemsRequest _$result;
    try {
      _$result = _$v ??
          _$ReorderPlanItemsRequest._(
            itemIds: itemIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'itemIds';
        itemIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ReorderPlanItemsRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
