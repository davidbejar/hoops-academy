// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanItem extends PlanItem {
  @override
  final String title;
  @override
  final String? description;
  @override
  final int? durationMinutes;
  @override
  final int? sets;
  @override
  final int? repetitions;
  @override
  final String? videoUrl;
  @override
  final String id;
  @override
  final int position;
  @override
  final String? exerciseId;

  factory _$PlanItem([void Function(PlanItemBuilder)? updates]) =>
      (PlanItemBuilder()..update(updates))._build();

  _$PlanItem._(
      {required this.title,
      this.description,
      this.durationMinutes,
      this.sets,
      this.repetitions,
      this.videoUrl,
      required this.id,
      required this.position,
      this.exerciseId})
      : super._();
  @override
  PlanItem rebuild(void Function(PlanItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanItemBuilder toBuilder() => PlanItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanItem &&
        title == other.title &&
        description == other.description &&
        durationMinutes == other.durationMinutes &&
        sets == other.sets &&
        repetitions == other.repetitions &&
        videoUrl == other.videoUrl &&
        id == other.id &&
        position == other.position &&
        exerciseId == other.exerciseId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, sets.hashCode);
    _$hash = $jc(_$hash, repetitions.hashCode);
    _$hash = $jc(_$hash, videoUrl.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, position.hashCode);
    _$hash = $jc(_$hash, exerciseId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanItem')
          ..add('title', title)
          ..add('description', description)
          ..add('durationMinutes', durationMinutes)
          ..add('sets', sets)
          ..add('repetitions', repetitions)
          ..add('videoUrl', videoUrl)
          ..add('id', id)
          ..add('position', position)
          ..add('exerciseId', exerciseId))
        .toString();
  }
}

class PlanItemBuilder implements Builder<PlanItem, PlanItemBuilder> {
  _$PlanItem? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  int? _sets;
  int? get sets => _$this._sets;
  set sets(int? sets) => _$this._sets = sets;

  int? _repetitions;
  int? get repetitions => _$this._repetitions;
  set repetitions(int? repetitions) => _$this._repetitions = repetitions;

  String? _videoUrl;
  String? get videoUrl => _$this._videoUrl;
  set videoUrl(String? videoUrl) => _$this._videoUrl = videoUrl;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _position;
  int? get position => _$this._position;
  set position(int? position) => _$this._position = position;

  String? _exerciseId;
  String? get exerciseId => _$this._exerciseId;
  set exerciseId(String? exerciseId) => _$this._exerciseId = exerciseId;

  PlanItemBuilder() {
    PlanItem._defaults(this);
  }

  PlanItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _description = $v.description;
      _durationMinutes = $v.durationMinutes;
      _sets = $v.sets;
      _repetitions = $v.repetitions;
      _videoUrl = $v.videoUrl;
      _id = $v.id;
      _position = $v.position;
      _exerciseId = $v.exerciseId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanItem other) {
    _$v = other as _$PlanItem;
  }

  @override
  void update(void Function(PlanItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanItem build() => _build();

  _$PlanItem _build() {
    final _$result = _$v ??
        _$PlanItem._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'PlanItem', 'title'),
          description: description,
          durationMinutes: durationMinutes,
          sets: sets,
          repetitions: repetitions,
          videoUrl: videoUrl,
          id: BuiltValueNullFieldError.checkNotNull(id, r'PlanItem', 'id'),
          position: BuiltValueNullFieldError.checkNotNull(
              position, r'PlanItem', 'position'),
          exerciseId: exerciseId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
