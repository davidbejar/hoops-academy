// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reject_approval_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RejectApprovalRequest extends RejectApprovalRequest {
  @override
  final String note;

  factory _$RejectApprovalRequest(
          [void Function(RejectApprovalRequestBuilder)? updates]) =>
      (RejectApprovalRequestBuilder()..update(updates))._build();

  _$RejectApprovalRequest._({required this.note}) : super._();
  @override
  RejectApprovalRequest rebuild(
          void Function(RejectApprovalRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RejectApprovalRequestBuilder toBuilder() =>
      RejectApprovalRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RejectApprovalRequest && note == other.note;
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
    return (newBuiltValueToStringHelper(r'RejectApprovalRequest')
          ..add('note', note))
        .toString();
  }
}

class RejectApprovalRequestBuilder
    implements Builder<RejectApprovalRequest, RejectApprovalRequestBuilder> {
  _$RejectApprovalRequest? _$v;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  RejectApprovalRequestBuilder() {
    RejectApprovalRequest._defaults(this);
  }

  RejectApprovalRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RejectApprovalRequest other) {
    _$v = other as _$RejectApprovalRequest;
  }

  @override
  void update(void Function(RejectApprovalRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RejectApprovalRequest build() => _build();

  _$RejectApprovalRequest _build() {
    final _$result = _$v ??
        _$RejectApprovalRequest._(
          note: BuiltValueNullFieldError.checkNotNull(
              note, r'RejectApprovalRequest', 'note'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
