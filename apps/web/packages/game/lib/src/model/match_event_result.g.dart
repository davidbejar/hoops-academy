// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchEventResult extends MatchEventResult {
  @override
  final String eventId;
  @override
  final MatchEventResultStatus status;
  @override
  final int? serverSeq;
  @override
  final MatchEventRejectionReason? reason;
  @override
  final String? message;

  factory _$MatchEventResult(
          [void Function(MatchEventResultBuilder)? updates]) =>
      (MatchEventResultBuilder()..update(updates))._build();

  _$MatchEventResult._(
      {required this.eventId,
      required this.status,
      this.serverSeq,
      this.reason,
      this.message})
      : super._();
  @override
  MatchEventResult rebuild(void Function(MatchEventResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchEventResultBuilder toBuilder() =>
      MatchEventResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchEventResult &&
        eventId == other.eventId &&
        status == other.status &&
        serverSeq == other.serverSeq &&
        reason == other.reason &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, eventId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, serverSeq.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchEventResult')
          ..add('eventId', eventId)
          ..add('status', status)
          ..add('serverSeq', serverSeq)
          ..add('reason', reason)
          ..add('message', message))
        .toString();
  }
}

class MatchEventResultBuilder
    implements Builder<MatchEventResult, MatchEventResultBuilder> {
  _$MatchEventResult? _$v;

  String? _eventId;
  String? get eventId => _$this._eventId;
  set eventId(String? eventId) => _$this._eventId = eventId;

  MatchEventResultStatus? _status;
  MatchEventResultStatus? get status => _$this._status;
  set status(MatchEventResultStatus? status) => _$this._status = status;

  int? _serverSeq;
  int? get serverSeq => _$this._serverSeq;
  set serverSeq(int? serverSeq) => _$this._serverSeq = serverSeq;

  MatchEventRejectionReason? _reason;
  MatchEventRejectionReason? get reason => _$this._reason;
  set reason(MatchEventRejectionReason? reason) => _$this._reason = reason;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  MatchEventResultBuilder() {
    MatchEventResult._defaults(this);
  }

  MatchEventResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _eventId = $v.eventId;
      _status = $v.status;
      _serverSeq = $v.serverSeq;
      _reason = $v.reason;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchEventResult other) {
    _$v = other as _$MatchEventResult;
  }

  @override
  void update(void Function(MatchEventResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchEventResult build() => _build();

  _$MatchEventResult _build() {
    final _$result = _$v ??
        _$MatchEventResult._(
          eventId: BuiltValueNullFieldError.checkNotNull(
              eventId, r'MatchEventResult', 'eventId'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'MatchEventResult', 'status'),
          serverSeq: serverSeq,
          reason: reason,
          message: message,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
