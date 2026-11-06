// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item_ref.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanItemRef extends PlanItemRef {
  @override
  final String planId;
  @override
  final String itemId;

  factory _$PlanItemRef([void Function(PlanItemRefBuilder)? updates]) =>
      (PlanItemRefBuilder()..update(updates))._build();

  _$PlanItemRef._({required this.planId, required this.itemId}) : super._();
  @override
  PlanItemRef rebuild(void Function(PlanItemRefBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanItemRefBuilder toBuilder() => PlanItemRefBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanItemRef &&
        planId == other.planId &&
        itemId == other.itemId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, itemId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanItemRef')
          ..add('planId', planId)
          ..add('itemId', itemId))
        .toString();
  }
}

class PlanItemRefBuilder implements Builder<PlanItemRef, PlanItemRefBuilder> {
  _$PlanItemRef? _$v;

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

  String? _itemId;
  String? get itemId => _$this._itemId;
  set itemId(String? itemId) => _$this._itemId = itemId;

  PlanItemRefBuilder() {
    PlanItemRef._defaults(this);
  }

  PlanItemRefBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _planId = $v.planId;
      _itemId = $v.itemId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanItemRef other) {
    _$v = other as _$PlanItemRef;
  }

  @override
  void update(void Function(PlanItemRefBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanItemRef build() => _build();

  _$PlanItemRef _build() {
    final _$result = _$v ??
        _$PlanItemRef._(
          planId: BuiltValueNullFieldError.checkNotNull(
              planId, r'PlanItemRef', 'planId'),
          itemId: BuiltValueNullFieldError.checkNotNull(
              itemId, r'PlanItemRef', 'itemId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
