// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrainingSession extends TrainingSession {
  @override
  final String id;
  @override
  final String teamId;
  @override
  final String? scheduleId;
  @override
  final DateTime startsAt;
  @override
  final int durationMinutes;
  @override
  final String? location;
  @override
  final TrainingSessionStatus status;
  @override
  final String? planId;
  @override
  final String? notes;
  @override
  final String? cancelReason;

  factory _$TrainingSession([void Function(TrainingSessionBuilder)? updates]) =>
      (TrainingSessionBuilder()..update(updates))._build();

  _$TrainingSession._(
      {required this.id,
      required this.teamId,
      this.scheduleId,
      required this.startsAt,
      required this.durationMinutes,
      this.location,
      required this.status,
      this.planId,
      this.notes,
      this.cancelReason})
      : super._();
  @override
  TrainingSession rebuild(void Function(TrainingSessionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrainingSessionBuilder toBuilder() => TrainingSessionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrainingSession &&
        id == other.id &&
        teamId == other.teamId &&
        scheduleId == other.scheduleId &&
        startsAt == other.startsAt &&
        durationMinutes == other.durationMinutes &&
        location == other.location &&
        status == other.status &&
        planId == other.planId &&
        notes == other.notes &&
        cancelReason == other.cancelReason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, scheduleId.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jc(_$hash, cancelReason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrainingSession')
          ..add('id', id)
          ..add('teamId', teamId)
          ..add('scheduleId', scheduleId)
          ..add('startsAt', startsAt)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('status', status)
          ..add('planId', planId)
          ..add('notes', notes)
          ..add('cancelReason', cancelReason))
        .toString();
  }
}

class TrainingSessionBuilder
    implements Builder<TrainingSession, TrainingSessionBuilder> {
  _$TrainingSession? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _scheduleId;
  String? get scheduleId => _$this._scheduleId;
  set scheduleId(String? scheduleId) => _$this._scheduleId = scheduleId;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  String? _location;
  String? get location => _$this._location;
  set location(String? location) => _$this._location = location;

  TrainingSessionStatus? _status;
  TrainingSessionStatus? get status => _$this._status;
  set status(TrainingSessionStatus? status) => _$this._status = status;

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  String? _cancelReason;
  String? get cancelReason => _$this._cancelReason;
  set cancelReason(String? cancelReason) => _$this._cancelReason = cancelReason;

  TrainingSessionBuilder() {
    TrainingSession._defaults(this);
  }

  TrainingSessionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _teamId = $v.teamId;
      _scheduleId = $v.scheduleId;
      _startsAt = $v.startsAt;
      _durationMinutes = $v.durationMinutes;
      _location = $v.location;
      _status = $v.status;
      _planId = $v.planId;
      _notes = $v.notes;
      _cancelReason = $v.cancelReason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrainingSession other) {
    _$v = other as _$TrainingSession;
  }

  @override
  void update(void Function(TrainingSessionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrainingSession build() => _build();

  _$TrainingSession _build() {
    final _$result = _$v ??
        _$TrainingSession._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'TrainingSession', 'id'),
          teamId: BuiltValueNullFieldError.checkNotNull(
              teamId, r'TrainingSession', 'teamId'),
          scheduleId: scheduleId,
          startsAt: BuiltValueNullFieldError.checkNotNull(
              startsAt, r'TrainingSession', 'startsAt'),
          durationMinutes: BuiltValueNullFieldError.checkNotNull(
              durationMinutes, r'TrainingSession', 'durationMinutes'),
          location: location,
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'TrainingSession', 'status'),
          planId: planId,
          notes: notes,
          cancelReason: cancelReason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
