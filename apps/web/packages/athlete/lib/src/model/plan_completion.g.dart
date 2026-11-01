// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_completion.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanCompletion extends PlanCompletion {
  @override
  final String? comment;
  @override
  final String id;
  @override
  final String assignmentId;
  @override
  final String playerId;
  @override
  final CompletionStatus status;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;

  factory _$PlanCompletion([void Function(PlanCompletionBuilder)? updates]) =>
      (PlanCompletionBuilder()..update(updates))._build();

  _$PlanCompletion._(
      {this.comment,
      required this.id,
      required this.assignmentId,
      required this.playerId,
      required this.status,
      required this.recordedBy,
      required this.recordedAt})
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
        comment == other.comment &&
        id == other.id &&
        assignmentId == other.assignmentId &&
        playerId == other.playerId &&
        status == other.status &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, assignmentId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanCompletion')
          ..add('comment', comment)
          ..add('id', id)
          ..add('assignmentId', assignmentId)
          ..add('playerId', playerId)
          ..add('status', status)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class PlanCompletionBuilder
    implements
        Builder<PlanCompletion, PlanCompletionBuilder>,
        AuditInfoBuilder {
  _$PlanCompletion? _$v;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(covariant String? comment) => _$this._comment = comment;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  String? _assignmentId;
  String? get assignmentId => _$this._assignmentId;
  set assignmentId(covariant String? assignmentId) =>
      _$this._assignmentId = assignmentId;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  CompletionStatus? _status;
  CompletionStatus? get status => _$this._status;
  set status(covariant CompletionStatus? status) => _$this._status = status;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  PlanCompletionBuilder() {
    PlanCompletion._defaults(this);
  }

  PlanCompletionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _comment = $v.comment;
      _id = $v.id;
      _assignmentId = $v.assignmentId;
      _playerId = $v.playerId;
      _status = $v.status;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant PlanCompletion other) {
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
            comment: comment,
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlanCompletion', 'id'),
            assignmentId: BuiltValueNullFieldError.checkNotNull(
                assignmentId, r'PlanCompletion', 'assignmentId'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlanCompletion', 'playerId'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'PlanCompletion', 'status'),
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PlanCompletion', 'recordedAt'),
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
