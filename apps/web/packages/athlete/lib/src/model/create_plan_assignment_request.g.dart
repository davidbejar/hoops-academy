// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_plan_assignment_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePlanAssignmentRequest extends CreatePlanAssignmentRequest {
  @override
  final String planId;
  @override
  final String? teamId;
  @override
  final String? playerId;
  @override
  final Date dueOn;
  @override
  final String? notes;

  factory _$CreatePlanAssignmentRequest(
          [void Function(CreatePlanAssignmentRequestBuilder)? updates]) =>
      (CreatePlanAssignmentRequestBuilder()..update(updates))._build();

  _$CreatePlanAssignmentRequest._(
      {required this.planId,
      this.teamId,
      this.playerId,
      required this.dueOn,
      this.notes})
      : super._();
  @override
  CreatePlanAssignmentRequest rebuild(
          void Function(CreatePlanAssignmentRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreatePlanAssignmentRequestBuilder toBuilder() =>
      CreatePlanAssignmentRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePlanAssignmentRequest &&
        planId == other.planId &&
        teamId == other.teamId &&
        playerId == other.playerId &&
        dueOn == other.dueOn &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, dueOn.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreatePlanAssignmentRequest')
          ..add('planId', planId)
          ..add('teamId', teamId)
          ..add('playerId', playerId)
          ..add('dueOn', dueOn)
          ..add('notes', notes))
        .toString();
  }
}

class CreatePlanAssignmentRequestBuilder
    implements
        Builder<CreatePlanAssignmentRequest,
            CreatePlanAssignmentRequestBuilder> {
  _$CreatePlanAssignmentRequest? _$v;

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

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

  CreatePlanAssignmentRequestBuilder() {
    CreatePlanAssignmentRequest._defaults(this);
  }

  CreatePlanAssignmentRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _planId = $v.planId;
      _teamId = $v.teamId;
      _playerId = $v.playerId;
      _dueOn = $v.dueOn;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePlanAssignmentRequest other) {
    _$v = other as _$CreatePlanAssignmentRequest;
  }

  @override
  void update(void Function(CreatePlanAssignmentRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePlanAssignmentRequest build() => _build();

  _$CreatePlanAssignmentRequest _build() {
    final _$result = _$v ??
        _$CreatePlanAssignmentRequest._(
          planId: BuiltValueNullFieldError.checkNotNull(
              planId, r'CreatePlanAssignmentRequest', 'planId'),
          teamId: teamId,
          playerId: playerId,
          dueOn: BuiltValueNullFieldError.checkNotNull(
              dueOn, r'CreatePlanAssignmentRequest', 'dueOn'),
          notes: notes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
