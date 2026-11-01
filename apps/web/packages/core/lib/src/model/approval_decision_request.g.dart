// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_decision_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ApprovalDecisionRequest extends ApprovalDecisionRequest {
  @override
  final String? note;

  factory _$ApprovalDecisionRequest(
          [void Function(ApprovalDecisionRequestBuilder)? updates]) =>
      (ApprovalDecisionRequestBuilder()..update(updates))._build();

  _$ApprovalDecisionRequest._({this.note}) : super._();
  @override
  ApprovalDecisionRequest rebuild(
          void Function(ApprovalDecisionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApprovalDecisionRequestBuilder toBuilder() =>
      ApprovalDecisionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApprovalDecisionRequest && note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ApprovalDecisionRequest')
          ..add('note', note))
        .toString();
  }
}

class ApprovalDecisionRequestBuilder
    implements
        Builder<ApprovalDecisionRequest, ApprovalDecisionRequestBuilder> {
  _$ApprovalDecisionRequest? _$v;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  ApprovalDecisionRequestBuilder() {
    ApprovalDecisionRequest._defaults(this);
  }

  ApprovalDecisionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApprovalDecisionRequest other) {
    _$v = other as _$ApprovalDecisionRequest;
  }

  @override
  void update(void Function(ApprovalDecisionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ApprovalDecisionRequest build() => _build();

  _$ApprovalDecisionRequest _build() {
    final _$result = _$v ??
        _$ApprovalDecisionRequest._(
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
