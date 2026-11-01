// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_assignment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanAssignment extends PlanAssignment {
  @override
  final String? notes;
  @override
  final Date dueOn;
  @override
  final String? teamId;
  @override
  final String id;
  @override
  final TrainingPlanSummary plan;
  @override
  final String? playerId;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;

  factory _$PlanAssignment([void Function(PlanAssignmentBuilder)? updates]) =>
      (PlanAssignmentBuilder()..update(updates))._build();

  _$PlanAssignment._(
      {this.notes,
      required this.dueOn,
      this.teamId,
      required this.id,
      required this.plan,
      this.playerId,
      required this.recordedBy,
      required this.recordedAt})
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
        notes == other.notes &&
        dueOn == other.dueOn &&
        teamId == other.teamId &&
        id == other.id &&
        plan == other.plan &&
        playerId == other.playerId &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jc(_$hash, dueOn.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, plan.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanAssignment')
          ..add('notes', notes)
          ..add('dueOn', dueOn)
          ..add('teamId', teamId)
          ..add('id', id)
          ..add('plan', plan)
          ..add('playerId', playerId)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class PlanAssignmentBuilder
    implements
        Builder<PlanAssignment, PlanAssignmentBuilder>,
        AuditInfoBuilder {
  _$PlanAssignment? _$v;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(covariant String? notes) => _$this._notes = notes;

  Date? _dueOn;
  Date? get dueOn => _$this._dueOn;
  set dueOn(covariant Date? dueOn) => _$this._dueOn = dueOn;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(covariant String? teamId) => _$this._teamId = teamId;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  TrainingPlanSummary? _plan;
  TrainingPlanSummary? get plan => _$this._plan;
  set plan(covariant TrainingPlanSummary? plan) => _$this._plan = plan;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  PlanAssignmentBuilder() {
    PlanAssignment._defaults(this);
  }

  PlanAssignmentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notes = $v.notes;
      _dueOn = $v.dueOn;
      _teamId = $v.teamId;
      _id = $v.id;
      _plan = $v.plan;
      _playerId = $v.playerId;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant PlanAssignment other) {
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
            notes: notes,
            dueOn: BuiltValueNullFieldError.checkNotNull(
                dueOn, r'PlanAssignment', 'dueOn'),
            teamId: teamId,
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlanAssignment', 'id'),
            plan: BuiltValueNullFieldError.checkNotNull(
                plan, r'PlanAssignment', 'plan'),
            playerId: playerId,
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PlanAssignment', 'recordedAt'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
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
