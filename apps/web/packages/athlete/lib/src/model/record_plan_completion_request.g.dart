// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_plan_completion_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RecordPlanCompletionRequest extends RecordPlanCompletionRequest {
  @override
  final CompletionStatus status;
  @override
  final String? comment;

  factory _$RecordPlanCompletionRequest(
          [void Function(RecordPlanCompletionRequestBuilder)? updates]) =>
      (RecordPlanCompletionRequestBuilder()..update(updates))._build();

  _$RecordPlanCompletionRequest._({required this.status, this.comment})
      : super._();
  @override
  RecordPlanCompletionRequest rebuild(
          void Function(RecordPlanCompletionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecordPlanCompletionRequestBuilder toBuilder() =>
      RecordPlanCompletionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RecordPlanCompletionRequest &&
        status == other.status &&
        comment == other.comment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RecordPlanCompletionRequest')
          ..add('status', status)
          ..add('comment', comment))
        .toString();
  }
}

class RecordPlanCompletionRequestBuilder
    implements
        Builder<RecordPlanCompletionRequest,
            RecordPlanCompletionRequestBuilder> {
  _$RecordPlanCompletionRequest? _$v;

  CompletionStatus? _status;
  CompletionStatus? get status => _$this._status;
  set status(CompletionStatus? status) => _$this._status = status;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  RecordPlanCompletionRequestBuilder() {
    RecordPlanCompletionRequest._defaults(this);
  }

  RecordPlanCompletionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _comment = $v.comment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RecordPlanCompletionRequest other) {
    _$v = other as _$RecordPlanCompletionRequest;
  }

  @override
  void update(void Function(RecordPlanCompletionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RecordPlanCompletionRequest build() => _build();

  _$RecordPlanCompletionRequest _build() {
    final _$result = _$v ??
        _$RecordPlanCompletionRequest._(
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'RecordPlanCompletionRequest', 'status'),
          comment: comment,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
