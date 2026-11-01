// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class TrainingPlanSummaryBuilder {
  void replace(TrainingPlanSummary other);
  void update(void Function(TrainingPlanSummaryBuilder) updates);
  String? get id;
  set id(String? id);

  String? get name;
  set name(String? name);

  String? get description;
  set description(String? description);

  bool? get template;
  set template(bool? template);

  String? get sourceTemplateId;
  set sourceTemplateId(String? sourceTemplateId);

  int? get itemCount;
  set itemCount(int? itemCount);

  int? get totalDurationMinutes;
  set totalDurationMinutes(int? totalDurationMinutes);
}

class _$$TrainingPlanSummary extends $TrainingPlanSummary {
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

  factory _$$TrainingPlanSummary(
          [void Function($TrainingPlanSummaryBuilder)? updates]) =>
      ($TrainingPlanSummaryBuilder()..update(updates))._build();

  _$$TrainingPlanSummary._(
      {required this.id,
      required this.name,
      this.description,
      required this.template,
      this.sourceTemplateId,
      required this.itemCount,
      required this.totalDurationMinutes})
      : super._();
  @override
  $TrainingPlanSummary rebuild(
          void Function($TrainingPlanSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $TrainingPlanSummaryBuilder toBuilder() =>
      $TrainingPlanSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $TrainingPlanSummary &&
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
    return (newBuiltValueToStringHelper(r'$TrainingPlanSummary')
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

class $TrainingPlanSummaryBuilder
    implements
        Builder<$TrainingPlanSummary, $TrainingPlanSummaryBuilder>,
        TrainingPlanSummaryBuilder {
  _$$TrainingPlanSummary? _$v;

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

  $TrainingPlanSummaryBuilder() {
    $TrainingPlanSummary._defaults(this);
  }

  $TrainingPlanSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(covariant $TrainingPlanSummary other) {
    _$v = other as _$$TrainingPlanSummary;
  }

  @override
  void update(void Function($TrainingPlanSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $TrainingPlanSummary build() => _build();

  _$$TrainingPlanSummary _build() {
    final _$result = _$v ??
        _$$TrainingPlanSummary._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'$TrainingPlanSummary', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'$TrainingPlanSummary', 'name'),
          description: description,
          template: BuiltValueNullFieldError.checkNotNull(
              template, r'$TrainingPlanSummary', 'template'),
          sourceTemplateId: sourceTemplateId,
          itemCount: BuiltValueNullFieldError.checkNotNull(
              itemCount, r'$TrainingPlanSummary', 'itemCount'),
          totalDurationMinutes: BuiltValueNullFieldError.checkNotNull(
              totalDurationMinutes,
              r'$TrainingPlanSummary',
              'totalDurationMinutes'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
