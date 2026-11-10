// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanItemSource extends PlanItemSource {
  @override
  final String? exerciseId;
  @override
  final String? planId;
  @override
  final String? itemId;

  factory _$PlanItemSource([void Function(PlanItemSourceBuilder)? updates]) =>
      (PlanItemSourceBuilder()..update(updates))._build();

  _$PlanItemSource._({this.exerciseId, this.planId, this.itemId}) : super._();
  @override
  PlanItemSource rebuild(void Function(PlanItemSourceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanItemSourceBuilder toBuilder() => PlanItemSourceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanItemSource &&
        exerciseId == other.exerciseId &&
        planId == other.planId &&
        itemId == other.itemId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, exerciseId.hashCode);
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, itemId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanItemSource')
          ..add('exerciseId', exerciseId)
          ..add('planId', planId)
          ..add('itemId', itemId))
        .toString();
  }
}

class PlanItemSourceBuilder
    implements Builder<PlanItemSource, PlanItemSourceBuilder> {
  _$PlanItemSource? _$v;

  String? _exerciseId;
  String? get exerciseId => _$this._exerciseId;
  set exerciseId(String? exerciseId) => _$this._exerciseId = exerciseId;

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

  String? _itemId;
  String? get itemId => _$this._itemId;
  set itemId(String? itemId) => _$this._itemId = itemId;

  PlanItemSourceBuilder() {
    PlanItemSource._defaults(this);
  }

  PlanItemSourceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _exerciseId = $v.exerciseId;
      _planId = $v.planId;
      _itemId = $v.itemId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanItemSource other) {
    _$v = other as _$PlanItemSource;
  }

  @override
  void update(void Function(PlanItemSourceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanItemSource build() => _build();

  _$PlanItemSource _build() {
    final _$result = _$v ??
        _$PlanItemSource._(
          exerciseId: exerciseId,
          planId: planId,
          itemId: itemId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
