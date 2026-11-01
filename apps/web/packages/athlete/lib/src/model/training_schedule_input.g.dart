// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_schedule_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class TrainingScheduleInputBuilder {
  void replace(TrainingScheduleInput other);
  void update(void Function(TrainingScheduleInputBuilder) updates);
  String? get teamId;
  set teamId(String? teamId);

  DayOfWeek? get dayOfWeek;
  set dayOfWeek(DayOfWeek? dayOfWeek);

  String? get startTime;
  set startTime(String? startTime);

  int? get durationMinutes;
  set durationMinutes(int? durationMinutes);

  String? get location;
  set location(String? location);

  Date? get validFrom;
  set validFrom(Date? validFrom);

  Date? get validUntil;
  set validUntil(Date? validUntil);
}

class _$$TrainingScheduleInput extends $TrainingScheduleInput {
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

  factory _$$TrainingScheduleInput(
          [void Function($TrainingScheduleInputBuilder)? updates]) =>
      ($TrainingScheduleInputBuilder()..update(updates))._build();

  _$$TrainingScheduleInput._(
      {required this.teamId,
      required this.dayOfWeek,
      required this.startTime,
      required this.durationMinutes,
      this.location,
      required this.validFrom,
      this.validUntil})
      : super._();
  @override
  $TrainingScheduleInput rebuild(
          void Function($TrainingScheduleInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $TrainingScheduleInputBuilder toBuilder() =>
      $TrainingScheduleInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $TrainingScheduleInput &&
        teamId == other.teamId &&
        dayOfWeek == other.dayOfWeek &&
        startTime == other.startTime &&
        durationMinutes == other.durationMinutes &&
        location == other.location &&
        validFrom == other.validFrom &&
        validUntil == other.validUntil;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$TrainingScheduleInput')
          ..add('teamId', teamId)
          ..add('dayOfWeek', dayOfWeek)
          ..add('startTime', startTime)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('validFrom', validFrom)
          ..add('validUntil', validUntil))
        .toString();
  }
}

class $TrainingScheduleInputBuilder
    implements
        Builder<$TrainingScheduleInput, $TrainingScheduleInputBuilder>,
        TrainingScheduleInputBuilder {
  _$$TrainingScheduleInput? _$v;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(covariant String? teamId) => _$this._teamId = teamId;

  DayOfWeek? _dayOfWeek;
  DayOfWeek? get dayOfWeek => _$this._dayOfWeek;
  set dayOfWeek(covariant DayOfWeek? dayOfWeek) =>
      _$this._dayOfWeek = dayOfWeek;

  String? _startTime;
  String? get startTime => _$this._startTime;
  set startTime(covariant String? startTime) => _$this._startTime = startTime;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(covariant int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  String? _location;
  String? get location => _$this._location;
  set location(covariant String? location) => _$this._location = location;

  Date? _validFrom;
  Date? get validFrom => _$this._validFrom;
  set validFrom(covariant Date? validFrom) => _$this._validFrom = validFrom;

  Date? _validUntil;
  Date? get validUntil => _$this._validUntil;
  set validUntil(covariant Date? validUntil) => _$this._validUntil = validUntil;

  $TrainingScheduleInputBuilder() {
    $TrainingScheduleInput._defaults(this);
  }

  $TrainingScheduleInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _teamId = $v.teamId;
      _dayOfWeek = $v.dayOfWeek;
      _startTime = $v.startTime;
      _durationMinutes = $v.durationMinutes;
      _location = $v.location;
      _validFrom = $v.validFrom;
      _validUntil = $v.validUntil;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $TrainingScheduleInput other) {
    _$v = other as _$$TrainingScheduleInput;
  }

  @override
  void update(void Function($TrainingScheduleInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $TrainingScheduleInput build() => _build();

  _$$TrainingScheduleInput _build() {
    final _$result = _$v ??
        _$$TrainingScheduleInput._(
          teamId: BuiltValueNullFieldError.checkNotNull(
              teamId, r'$TrainingScheduleInput', 'teamId'),
          dayOfWeek: BuiltValueNullFieldError.checkNotNull(
              dayOfWeek, r'$TrainingScheduleInput', 'dayOfWeek'),
          startTime: BuiltValueNullFieldError.checkNotNull(
              startTime, r'$TrainingScheduleInput', 'startTime'),
          durationMinutes: BuiltValueNullFieldError.checkNotNull(
              durationMinutes, r'$TrainingScheduleInput', 'durationMinutes'),
          location: location,
          validFrom: BuiltValueNullFieldError.checkNotNull(
              validFrom, r'$TrainingScheduleInput', 'validFrom'),
          validUntil: validUntil,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
