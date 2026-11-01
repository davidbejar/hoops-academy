// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_training_session_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateTrainingSessionRequest extends CreateTrainingSessionRequest {
  @override
  final String teamId;
  @override
  final DateTime startsAt;
  @override
  final int durationMinutes;
  @override
  final String? location;
  @override
  final String? planId;
  @override
  final String? notes;

  factory _$CreateTrainingSessionRequest(
          [void Function(CreateTrainingSessionRequestBuilder)? updates]) =>
      (CreateTrainingSessionRequestBuilder()..update(updates))._build();

  _$CreateTrainingSessionRequest._(
      {required this.teamId,
      required this.startsAt,
      required this.durationMinutes,
      this.location,
      this.planId,
      this.notes})
      : super._();
  @override
  CreateTrainingSessionRequest rebuild(
          void Function(CreateTrainingSessionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTrainingSessionRequestBuilder toBuilder() =>
      CreateTrainingSessionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTrainingSessionRequest &&
        teamId == other.teamId &&
        startsAt == other.startsAt &&
        durationMinutes == other.durationMinutes &&
        location == other.location &&
        planId == other.planId &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTrainingSessionRequest')
          ..add('teamId', teamId)
          ..add('startsAt', startsAt)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('planId', planId)
          ..add('notes', notes))
        .toString();
  }
}

class CreateTrainingSessionRequestBuilder
    implements
        Builder<CreateTrainingSessionRequest,
            CreateTrainingSessionRequestBuilder> {
  _$CreateTrainingSessionRequest? _$v;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

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

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  CreateTrainingSessionRequestBuilder() {
    CreateTrainingSessionRequest._defaults(this);
  }

  CreateTrainingSessionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _teamId = $v.teamId;
      _startsAt = $v.startsAt;
      _durationMinutes = $v.durationMinutes;
      _location = $v.location;
      _planId = $v.planId;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTrainingSessionRequest other) {
    _$v = other as _$CreateTrainingSessionRequest;
  }

  @override
  void update(void Function(CreateTrainingSessionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTrainingSessionRequest build() => _build();

  _$CreateTrainingSessionRequest _build() {
    final _$result = _$v ??
        _$CreateTrainingSessionRequest._(
          teamId: BuiltValueNullFieldError.checkNotNull(
              teamId, r'CreateTrainingSessionRequest', 'teamId'),
          startsAt: BuiltValueNullFieldError.checkNotNull(
              startsAt, r'CreateTrainingSessionRequest', 'startsAt'),
          durationMinutes: BuiltValueNullFieldError.checkNotNull(
              durationMinutes,
              r'CreateTrainingSessionRequest',
              'durationMinutes'),
          location: location,
          planId: planId,
          notes: notes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
