// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_schedule.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrainingSchedule extends TrainingSchedule {
  @override
  final String teamId;
  @override
  final DayOfWeek dayOfWeek;
  @override
  final String startTime;
  @override
  final int durationMinutes;
  @override
  final String? location;
  @override
  final Date validFrom;
  @override
  final Date? validUntil;
  @override
  final String id;

  factory _$TrainingSchedule(
          [void Function(TrainingScheduleBuilder)? updates]) =>
      (TrainingScheduleBuilder()..update(updates))._build();

  _$TrainingSchedule._(
      {required this.teamId,
      required this.dayOfWeek,
      required this.startTime,
      required this.durationMinutes,
      this.location,
      required this.validFrom,
      this.validUntil,
      required this.id})
      : super._();
  @override
  TrainingSchedule rebuild(void Function(TrainingScheduleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrainingScheduleBuilder toBuilder() =>
      TrainingScheduleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrainingSchedule &&
        teamId == other.teamId &&
        dayOfWeek == other.dayOfWeek &&
        startTime == other.startTime &&
        durationMinutes == other.durationMinutes &&
        location == other.location &&
        validFrom == other.validFrom &&
        validUntil == other.validUntil &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, dayOfWeek.hashCode);
    _$hash = $jc(_$hash, startTime.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, validFrom.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrainingSchedule')
          ..add('teamId', teamId)
          ..add('dayOfWeek', dayOfWeek)
          ..add('startTime', startTime)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('validFrom', validFrom)
          ..add('validUntil', validUntil)
          ..add('id', id))
        .toString();
  }
}

class TrainingScheduleBuilder
    implements Builder<TrainingSchedule, TrainingScheduleBuilder> {
  _$TrainingSchedule? _$v;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  DayOfWeek? _dayOfWeek;
  DayOfWeek? get dayOfWeek => _$this._dayOfWeek;
  set dayOfWeek(DayOfWeek? dayOfWeek) => _$this._dayOfWeek = dayOfWeek;

  String? _startTime;
  String? get startTime => _$this._startTime;
  set startTime(String? startTime) => _$this._startTime = startTime;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  String? _location;
  String? get location => _$this._location;
  set location(String? location) => _$this._location = location;

  Date? _validFrom;
  Date? get validFrom => _$this._validFrom;
  set validFrom(Date? validFrom) => _$this._validFrom = validFrom;

  Date? _validUntil;
  Date? get validUntil => _$this._validUntil;
  set validUntil(Date? validUntil) => _$this._validUntil = validUntil;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  TrainingScheduleBuilder() {
    TrainingSchedule._defaults(this);
  }

  TrainingScheduleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _teamId = $v.teamId;
      _dayOfWeek = $v.dayOfWeek;
      _startTime = $v.startTime;
      _durationMinutes = $v.durationMinutes;
      _location = $v.location;
      _validFrom = $v.validFrom;
      _validUntil = $v.validUntil;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrainingSchedule other) {
    _$v = other as _$TrainingSchedule;
  }

  @override
  void update(void Function(TrainingScheduleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrainingSchedule build() => _build();

  _$TrainingSchedule _build() {
    final _$result = _$v ??
        _$TrainingSchedule._(
          teamId: BuiltValueNullFieldError.checkNotNull(
              teamId, r'TrainingSchedule', 'teamId'),
          dayOfWeek: BuiltValueNullFieldError.checkNotNull(
              dayOfWeek, r'TrainingSchedule', 'dayOfWeek'),
          startTime: BuiltValueNullFieldError.checkNotNull(
              startTime, r'TrainingSchedule', 'startTime'),
          durationMinutes: BuiltValueNullFieldError.checkNotNull(
              durationMinutes, r'TrainingSchedule', 'durationMinutes'),
          location: location,
          validFrom: BuiltValueNullFieldError.checkNotNull(
              validFrom, r'TrainingSchedule', 'validFrom'),
          validUntil: validUntil,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'TrainingSchedule', 'id'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
