// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrainingPlan extends TrainingPlan {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? nameKey;
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
  @override
  final bool? archived;
  @override
  final String? sessionId;
  @override
  final BuiltList<PlanItem> items;

  factory _$TrainingPlan([void Function(TrainingPlanBuilder)? updates]) =>
      (TrainingPlanBuilder()..update(updates))._build();

  _$TrainingPlan._(
      {required this.id,
      required this.name,
      this.nameKey,
      this.description,
      required this.template,
      this.sourceTemplateId,
      required this.itemCount,
      required this.totalDurationMinutes,
      this.archived,
      this.sessionId,
      required this.items})
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
        id == other.id &&
        name == other.name &&
        nameKey == other.nameKey &&
        description == other.description &&
        template == other.template &&
        sourceTemplateId == other.sourceTemplateId &&
        itemCount == other.itemCount &&
        totalDurationMinutes == other.totalDurationMinutes &&
        archived == other.archived &&
        sessionId == other.sessionId &&
        items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameKey.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, template.hashCode);
    _$hash = $jc(_$hash, sourceTemplateId.hashCode);
    _$hash = $jc(_$hash, itemCount.hashCode);
    _$hash = $jc(_$hash, totalDurationMinutes.hashCode);
    _$hash = $jc(_$hash, archived.hashCode);
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrainingPlan')
          ..add('id', id)
          ..add('name', name)
          ..add('nameKey', nameKey)
          ..add('description', description)
          ..add('template', template)
          ..add('sourceTemplateId', sourceTemplateId)
          ..add('itemCount', itemCount)
          ..add('totalDurationMinutes', totalDurationMinutes)
          ..add('archived', archived)
          ..add('sessionId', sessionId)
          ..add('items', items))
        .toString();
  }
}

class TrainingPlanBuilder
    implements Builder<TrainingPlan, TrainingPlanBuilder> {
  _$TrainingPlan? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameKey;
  String? get nameKey => _$this._nameKey;
  set nameKey(String? nameKey) => _$this._nameKey = nameKey;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  bool? _template;
  bool? get template => _$this._template;
  set template(bool? template) => _$this._template = template;

  String? _sourceTemplateId;
  String? get sourceTemplateId => _$this._sourceTemplateId;
  set sourceTemplateId(String? sourceTemplateId) =>
      _$this._sourceTemplateId = sourceTemplateId;

  int? _itemCount;
  int? get itemCount => _$this._itemCount;
  set itemCount(int? itemCount) => _$this._itemCount = itemCount;

  int? _totalDurationMinutes;
  int? get totalDurationMinutes => _$this._totalDurationMinutes;
  set totalDurationMinutes(int? totalDurationMinutes) =>
      _$this._totalDurationMinutes = totalDurationMinutes;

  bool? _archived;
  bool? get archived => _$this._archived;
  set archived(bool? archived) => _$this._archived = archived;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  ListBuilder<PlanItem>? _items;
  ListBuilder<PlanItem> get items => _$this._items ??= ListBuilder<PlanItem>();
  set items(ListBuilder<PlanItem>? items) => _$this._items = items;

  TrainingPlanBuilder() {
    TrainingPlan._defaults(this);
  }

  TrainingPlanBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _nameKey = $v.nameKey;
      _description = $v.description;
      _template = $v.template;
      _sourceTemplateId = $v.sourceTemplateId;
      _itemCount = $v.itemCount;
      _totalDurationMinutes = $v.totalDurationMinutes;
      _archived = $v.archived;
      _sessionId = $v.sessionId;
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrainingPlan other) {
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
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'TrainingPlan', 'id'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'TrainingPlan', 'name'),
            nameKey: nameKey,
            description: description,
            template: BuiltValueNullFieldError.checkNotNull(
                template, r'TrainingPlan', 'template'),
            sourceTemplateId: sourceTemplateId,
            itemCount: BuiltValueNullFieldError.checkNotNull(
                itemCount, r'TrainingPlan', 'itemCount'),
            totalDurationMinutes: BuiltValueNullFieldError.checkNotNull(
                totalDurationMinutes, r'TrainingPlan', 'totalDurationMinutes'),
            archived: archived,
            sessionId: sessionId,
            items: items.build(),
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
