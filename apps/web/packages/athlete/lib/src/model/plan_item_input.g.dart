// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanItemInput extends PlanItemInput {
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

  factory _$PlanItemInput([void Function(PlanItemInputBuilder)? updates]) =>
      (PlanItemInputBuilder()..update(updates))._build();

  _$PlanItemInput._(
      {required this.title,
      this.description,
      this.durationMinutes,
      this.sets,
      this.repetitions,
      this.videoUrl})
      : super._();
  @override
  PlanItemInput rebuild(void Function(PlanItemInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanItemInputBuilder toBuilder() => PlanItemInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanItemInput &&
        title == other.title &&
        description == other.description &&
        durationMinutes == other.durationMinutes &&
        sets == other.sets &&
        repetitions == other.repetitions &&
        videoUrl == other.videoUrl;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanItemInput')
          ..add('title', title)
          ..add('description', description)
          ..add('durationMinutes', durationMinutes)
          ..add('sets', sets)
          ..add('repetitions', repetitions)
          ..add('videoUrl', videoUrl))
        .toString();
  }
}

class PlanItemInputBuilder
    implements Builder<PlanItemInput, PlanItemInputBuilder> {
  _$PlanItemInput? _$v;

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

  PlanItemInputBuilder() {
    PlanItemInput._defaults(this);
  }

  PlanItemInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _description = $v.description;
      _durationMinutes = $v.durationMinutes;
      _sets = $v.sets;
      _repetitions = $v.repetitions;
      _videoUrl = $v.videoUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanItemInput other) {
    _$v = other as _$PlanItemInput;
  }

  @override
  void update(void Function(PlanItemInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanItemInput build() => _build();

  _$PlanItemInput _build() {
    final _$result = _$v ??
        _$PlanItemInput._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'PlanItemInput', 'title'),
          description: description,
          durationMinutes: durationMinutes,
          sets: sets,
          repetitions: repetitions,
          videoUrl: videoUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
