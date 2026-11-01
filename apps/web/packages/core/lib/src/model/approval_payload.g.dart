// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ApprovalPayload extends ApprovalPayload {
  @override
  final String? teamId;
  @override
  final String? jerseyNumber;
  @override
  final String? note;
  @override
  final String? reason;

  factory _$ApprovalPayload([void Function(ApprovalPayloadBuilder)? updates]) =>
      (ApprovalPayloadBuilder()..update(updates))._build();

  _$ApprovalPayload._({this.teamId, this.jerseyNumber, this.note, this.reason})
      : super._();
  @override
  ApprovalPayload rebuild(void Function(ApprovalPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ApprovalPayloadBuilder toBuilder() => ApprovalPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ApprovalPayload &&
        teamId == other.teamId &&
        jerseyNumber == other.jerseyNumber &&
        note == other.note &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ApprovalPayload')
          ..add('teamId', teamId)
          ..add('jerseyNumber', jerseyNumber)
          ..add('note', note)
          ..add('reason', reason))
        .toString();
  }
}

class ApprovalPayloadBuilder
    implements Builder<ApprovalPayload, ApprovalPayloadBuilder> {
  _$ApprovalPayload? _$v;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  ApprovalPayloadBuilder() {
    ApprovalPayload._defaults(this);
  }

  ApprovalPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _teamId = $v.teamId;
      _jerseyNumber = $v.jerseyNumber;
      _note = $v.note;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ApprovalPayload other) {
    _$v = other as _$ApprovalPayload;
  }

  @override
  void update(void Function(ApprovalPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ApprovalPayload build() => _build();

  _$ApprovalPayload _build() {
    final _$result = _$v ??
        _$ApprovalPayload._(
          teamId: teamId,
          jerseyNumber: jerseyNumber,
          note: note,
          reason: reason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
