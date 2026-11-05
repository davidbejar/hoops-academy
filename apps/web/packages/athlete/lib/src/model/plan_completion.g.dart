// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_completion.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanCompletion extends PlanCompletion {
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String id;
  @override
  final String assignmentId;
  @override
  final String playerId;
  @override
  final CompletionStatus status;
  @override
  final String? comment;

  factory _$PlanCompletion([void Function(PlanCompletionBuilder)? updates]) =>
      (PlanCompletionBuilder()..update(updates))._build();

  _$PlanCompletion._(
      {required this.recordedBy,
      required this.recordedAt,
      required this.id,
      required this.assignmentId,
      required this.playerId,
      required this.status,
      this.comment})
      : super._();
  @override
  PlanCompletion rebuild(void Function(PlanCompletionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanCompletionBuilder toBuilder() => PlanCompletionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanCompletion &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        id == other.id &&
        assignmentId == other.assignmentId &&
        playerId == other.playerId &&
        status == other.status &&
        comment == other.comment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, assignmentId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanCompletion')
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('id', id)
          ..add('assignmentId', assignmentId)
          ..add('playerId', playerId)
          ..add('status', status)
          ..add('comment', comment))
        .toString();
  }
}

class PlanCompletionBuilder
    implements Builder<PlanCompletion, PlanCompletionBuilder> {
  _$PlanCompletion? _$v;

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

  String? _assignmentId;
  String? get assignmentId => _$this._assignmentId;
  set assignmentId(String? assignmentId) => _$this._assignmentId = assignmentId;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  CompletionStatus? _status;
  CompletionStatus? get status => _$this._status;
  set status(CompletionStatus? status) => _$this._status = status;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  PlanCompletionBuilder() {
    PlanCompletion._defaults(this);
  }

  PlanCompletionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _id = $v.id;
      _assignmentId = $v.assignmentId;
      _playerId = $v.playerId;
      _status = $v.status;
      _comment = $v.comment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanCompletion other) {
    _$v = other as _$PlanCompletion;
  }

  @override
  void update(void Function(PlanCompletionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanCompletion build() => _build();

  _$PlanCompletion _build() {
    _$PlanCompletion _$result;
    try {
      _$result = _$v ??
          _$PlanCompletion._(
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PlanCompletion', 'recordedAt'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlanCompletion', 'id'),
            assignmentId: BuiltValueNullFieldError.checkNotNull(
                assignmentId, r'PlanCompletion', 'assignmentId'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlanCompletion', 'playerId'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'PlanCompletion', 'status'),
            comment: comment,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlanCompletion', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
