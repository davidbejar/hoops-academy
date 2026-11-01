// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_training_schedule_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateTrainingScheduleRequest extends UpdateTrainingScheduleRequest {
  @override
  final DayOfWeek? dayOfWeek;
  @override
  final String? startTime;
  @override
  final int? durationMinutes;
  @override
  final String? location;
  @override
  final Date? validFrom;
  @override
  final Date? validUntil;

  factory _$UpdateTrainingScheduleRequest(
          [void Function(UpdateTrainingScheduleRequestBuilder)? updates]) =>
      (UpdateTrainingScheduleRequestBuilder()..update(updates))._build();

  _$UpdateTrainingScheduleRequest._(
      {this.dayOfWeek,
      this.startTime,
      this.durationMinutes,
      this.location,
      this.validFrom,
      this.validUntil})
      : super._();
  @override
  UpdateTrainingScheduleRequest rebuild(
          void Function(UpdateTrainingScheduleRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTrainingScheduleRequestBuilder toBuilder() =>
      UpdateTrainingScheduleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTrainingScheduleRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateTrainingScheduleRequest')
          ..add('dayOfWeek', dayOfWeek)
          ..add('startTime', startTime)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('validFrom', validFrom)
          ..add('validUntil', validUntil))
        .toString();
  }
}

class UpdateTrainingScheduleRequestBuilder
    implements
        Builder<UpdateTrainingScheduleRequest,
            UpdateTrainingScheduleRequestBuilder> {
  _$UpdateTrainingScheduleRequest? _$v;

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

  UpdateTrainingScheduleRequestBuilder() {
    UpdateTrainingScheduleRequest._defaults(this);
  }

  UpdateTrainingScheduleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(UpdateTrainingScheduleRequest other) {
    _$v = other as _$UpdateTrainingScheduleRequest;
  }

  @override
  void update(void Function(UpdateTrainingScheduleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTrainingScheduleRequest build() => _build();

  _$UpdateTrainingScheduleRequest _build() {
    final _$result = _$v ??
        _$UpdateTrainingScheduleRequest._(
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          durationMinutes: durationMinutes,
          location: location,
          validFrom: validFrom,
          validUntil: validUntil,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
