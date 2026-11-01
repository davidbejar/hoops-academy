// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrainingPlan extends TrainingPlan {
  @override
  final BuiltList<PlanItem> items;
  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final bool template;
  @override
  final String? sourceTemplateId;
  @override
  final int itemCount;
  @override
  final int totalDurationMinutes;

  factory _$TrainingPlan([void Function(TrainingPlanBuilder)? updates]) =>
      (TrainingPlanBuilder()..update(updates))._build();

  _$TrainingPlan._(
      {required this.items,
      required this.id,
      required this.name,
      this.description,
      required this.template,
      this.sourceTemplateId,
      required this.itemCount,
      required this.totalDurationMinutes})
      : super._();
  @override
  TrainingPlan rebuild(void Function(TrainingPlanBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrainingPlanBuilder toBuilder() => TrainingPlanBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrainingPlan &&
        items == other.items &&
        id == other.id &&
        name == other.name &&
        description == other.description &&
        template == other.template &&
        sourceTemplateId == other.sourceTemplateId &&
        itemCount == other.itemCount &&
        totalDurationMinutes == other.totalDurationMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, template.hashCode);
    _$hash = $jc(_$hash, sourceTemplateId.hashCode);
    _$hash = $jc(_$hash, itemCount.hashCode);
    _$hash = $jc(_$hash, totalDurationMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrainingPlan')
          ..add('items', items)
          ..add('id', id)
          ..add('name', name)
          ..add('description', description)
          ..add('template', template)
          ..add('sourceTemplateId', sourceTemplateId)
          ..add('itemCount', itemCount)
          ..add('totalDurationMinutes', totalDurationMinutes))
        .toString();
  }
}

class TrainingPlanBuilder
    implements
        Builder<TrainingPlan, TrainingPlanBuilder>,
        TrainingPlanSummaryBuilder {
  _$TrainingPlan? _$v;

  ListBuilder<PlanItem>? _items;
  ListBuilder<PlanItem> get items => _$this._items ??= ListBuilder<PlanItem>();
  set items(covariant ListBuilder<PlanItem>? items) => _$this._items = items;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(covariant String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(covariant String? description) =>
      _$this._description = description;

  bool? _template;
  bool? get template => _$this._template;
  set template(covariant bool? template) => _$this._template = template;

  String? _sourceTemplateId;
  String? get sourceTemplateId => _$this._sourceTemplateId;
  set sourceTemplateId(covariant String? sourceTemplateId) =>
      _$this._sourceTemplateId = sourceTemplateId;

  int? _itemCount;
  int? get itemCount => _$this._itemCount;
  set itemCount(covariant int? itemCount) => _$this._itemCount = itemCount;

  int? _totalDurationMinutes;
  int? get totalDurationMinutes => _$this._totalDurationMinutes;
  set totalDurationMinutes(covariant int? totalDurationMinutes) =>
      _$this._totalDurationMinutes = totalDurationMinutes;

  TrainingPlanBuilder() {
    TrainingPlan._defaults(this);
  }

  TrainingPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _id = $v.id;
      _name = $v.name;
      _description = $v.description;
      _template = $v.template;
      _sourceTemplateId = $v.sourceTemplateId;
      _itemCount = $v.itemCount;
      _totalDurationMinutes = $v.totalDurationMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant TrainingPlan other) {
    _$v = other as _$TrainingPlan;
  }

  @override
  void update(void Function(TrainingPlanBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrainingPlan build() => _build();

  _$TrainingPlan _build() {
    _$TrainingPlan _$result;
    try {
      _$result = _$v ??
          _$TrainingPlan._(
            items: items.build(),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'TrainingPlan', 'id'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'TrainingPlan', 'name'),
            description: description,
            template: BuiltValueNullFieldError.checkNotNull(
                template, r'TrainingPlan', 'template'),
            sourceTemplateId: sourceTemplateId,
            itemCount: BuiltValueNullFieldError.checkNotNull(
                itemCount, r'TrainingPlan', 'itemCount'),
            totalDurationMinutes: BuiltValueNullFieldError.checkNotNull(
                totalDurationMinutes, r'TrainingPlan', 'totalDurationMinutes'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TrainingPlan', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
