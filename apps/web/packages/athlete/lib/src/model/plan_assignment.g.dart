// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_assignment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanAssignment extends PlanAssignment {
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String id;
  @override
  final TrainingPlanSummary plan;
  @override
  final String? teamId;
  @override
  final String? playerId;
  @override
  final Date dueOn;
  @override
  final String? notes;

  factory _$PlanAssignment([void Function(PlanAssignmentBuilder)? updates]) =>
      (PlanAssignmentBuilder()..update(updates))._build();

  _$PlanAssignment._(
      {required this.recordedBy,
      required this.recordedAt,
      required this.id,
      required this.plan,
      this.teamId,
      this.playerId,
      required this.dueOn,
      this.notes})
      : super._();
  @override
  PlanAssignment rebuild(void Function(PlanAssignmentBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanAssignmentBuilder toBuilder() => PlanAssignmentBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanAssignment &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        id == other.id &&
        plan == other.plan &&
        teamId == other.teamId &&
        playerId == other.playerId &&
        dueOn == other.dueOn &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, plan.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, dueOn.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanAssignment')
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('id', id)
          ..add('plan', plan)
          ..add('teamId', teamId)
          ..add('playerId', playerId)
          ..add('dueOn', dueOn)
          ..add('notes', notes))
        .toString();
  }
}

class PlanAssignmentBuilder
    implements Builder<PlanAssignment, PlanAssignmentBuilder> {
  _$PlanAssignment? _$v;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(DateTime? recordedAt) => _$this._recordedAt = recordedAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  TrainingPlanSummaryBuilder? _plan;
  TrainingPlanSummaryBuilder get plan =>
      _$this._plan ??= TrainingPlanSummaryBuilder();
  set plan(TrainingPlanSummaryBuilder? plan) => _$this._plan = plan;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  Date? _dueOn;
  Date? get dueOn => _$this._dueOn;
  set dueOn(Date? dueOn) => _$this._dueOn = dueOn;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  PlanAssignmentBuilder() {
    PlanAssignment._defaults(this);
  }

  PlanAssignmentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _id = $v.id;
      _plan = $v.plan.toBuilder();
      _teamId = $v.teamId;
      _playerId = $v.playerId;
      _dueOn = $v.dueOn;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanAssignment other) {
    _$v = other as _$PlanAssignment;
  }

  @override
  void update(void Function(PlanAssignmentBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanAssignment build() => _build();

  _$PlanAssignment _build() {
    _$PlanAssignment _$result;
    try {
      _$result = _$v ??
          _$PlanAssignment._(
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PlanAssignment', 'recordedAt'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlanAssignment', 'id'),
            plan: plan.build(),
            teamId: teamId,
            playerId: playerId,
            dueOn: BuiltValueNullFieldError.checkNotNull(
                dueOn, r'PlanAssignment', 'dueOn'),
            notes: notes,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();

        _$failedField = 'plan';
        plan.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlanAssignment', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
