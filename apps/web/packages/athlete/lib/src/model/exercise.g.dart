// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Exercise extends Exercise {
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
  final String? nameKey;
  @override
  final bool global;
  @override
  final bool archived;

  factory _$Exercise([void Function(ExerciseBuilder)? updates]) =>
      (ExerciseBuilder()..update(updates))._build();

  _$Exercise._(
      {required this.title,
      this.description,
      this.durationMinutes,
      this.sets,
      this.repetitions,
      this.videoUrl,
      required this.id,
      this.nameKey,
      required this.global,
      required this.archived})
      : super._();
  @override
  Exercise rebuild(void Function(ExerciseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExerciseBuilder toBuilder() => ExerciseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Exercise &&
        title == other.title &&
        description == other.description &&
        durationMinutes == other.durationMinutes &&
        sets == other.sets &&
        repetitions == other.repetitions &&
        videoUrl == other.videoUrl &&
        id == other.id &&
        nameKey == other.nameKey &&
        global == other.global &&
        archived == other.archived;
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
    _$hash = $jc(_$hash, nameKey.hashCode);
    _$hash = $jc(_$hash, global.hashCode);
    _$hash = $jc(_$hash, archived.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Exercise')
          ..add('title', title)
          ..add('description', description)
          ..add('durationMinutes', durationMinutes)
          ..add('sets', sets)
          ..add('repetitions', repetitions)
          ..add('videoUrl', videoUrl)
          ..add('id', id)
          ..add('nameKey', nameKey)
          ..add('global', global)
          ..add('archived', archived))
        .toString();
  }
}

class ExerciseBuilder implements Builder<Exercise, ExerciseBuilder> {
  _$Exercise? _$v;

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

  String? _nameKey;
  String? get nameKey => _$this._nameKey;
  set nameKey(String? nameKey) => _$this._nameKey = nameKey;

  bool? _global;
  bool? get global => _$this._global;
  set global(bool? global) => _$this._global = global;

  bool? _archived;
  bool? get archived => _$this._archived;
  set archived(bool? archived) => _$this._archived = archived;

  ExerciseBuilder() {
    Exercise._defaults(this);
  }

  ExerciseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _description = $v.description;
      _durationMinutes = $v.durationMinutes;
      _sets = $v.sets;
      _repetitions = $v.repetitions;
      _videoUrl = $v.videoUrl;
      _id = $v.id;
      _nameKey = $v.nameKey;
      _global = $v.global;
      _archived = $v.archived;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Exercise other) {
    _$v = other as _$Exercise;
  }

  @override
  void update(void Function(ExerciseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Exercise build() => _build();

  _$Exercise _build() {
    final _$result = _$v ??
        _$Exercise._(
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'Exercise', 'title'),
          description: description,
          durationMinutes: durationMinutes,
          sets: sets,
          repetitions: repetitions,
          videoUrl: videoUrl,
          id: BuiltValueNullFieldError.checkNotNull(id, r'Exercise', 'id'),
          nameKey: nameKey,
          global: BuiltValueNullFieldError.checkNotNull(
              global, r'Exercise', 'global'),
          archived: BuiltValueNullFieldError.checkNotNull(
              archived, r'Exercise', 'archived'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
