// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_match_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StoredMatchEvent extends StoredMatchEvent {
  @override
  final int serverSeq;
  @override
  final MatchEvent event;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime receivedAt;
  @override
  final String? voidedByEventId;

  factory _$StoredMatchEvent(
          [void Function(StoredMatchEventBuilder)? updates]) =>
      (StoredMatchEventBuilder()..update(updates))._build();

  _$StoredMatchEvent._(
      {required this.serverSeq,
      required this.event,
      required this.recordedBy,
      required this.receivedAt,
      this.voidedByEventId})
      : super._();
  @override
  StoredMatchEvent rebuild(void Function(StoredMatchEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StoredMatchEventBuilder toBuilder() =>
      StoredMatchEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StoredMatchEvent &&
        serverSeq == other.serverSeq &&
        event == other.event &&
        recordedBy == other.recordedBy &&
        receivedAt == other.receivedAt &&
        voidedByEventId == other.voidedByEventId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, serverSeq.hashCode);
    _$hash = $jc(_$hash, event.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, receivedAt.hashCode);
    _$hash = $jc(_$hash, voidedByEventId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'StoredMatchEvent')
          ..add('serverSeq', serverSeq)
          ..add('event', event)
          ..add('recordedBy', recordedBy)
          ..add('receivedAt', receivedAt)
          ..add('voidedByEventId', voidedByEventId))
        .toString();
  }
}

class StoredMatchEventBuilder
    implements Builder<StoredMatchEvent, StoredMatchEventBuilder> {
  _$StoredMatchEvent? _$v;

  int? _serverSeq;
  int? get serverSeq => _$this._serverSeq;
  set serverSeq(int? serverSeq) => _$this._serverSeq = serverSeq;

  MatchEventBuilder? _event;
  MatchEventBuilder get event => _$this._event ??= MatchEventBuilder();
  set event(MatchEventBuilder? event) => _$this._event = event;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _receivedAt;
  DateTime? get receivedAt => _$this._receivedAt;
  set receivedAt(DateTime? receivedAt) => _$this._receivedAt = receivedAt;

  String? _voidedByEventId;
  String? get voidedByEventId => _$this._voidedByEventId;
  set voidedByEventId(String? voidedByEventId) =>
      _$this._voidedByEventId = voidedByEventId;

  StoredMatchEventBuilder() {
    StoredMatchEvent._defaults(this);
  }

  StoredMatchEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _serverSeq = $v.serverSeq;
      _event = $v.event.toBuilder();
      _recordedBy = $v.recordedBy.toBuilder();
      _receivedAt = $v.receivedAt;
      _voidedByEventId = $v.voidedByEventId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StoredMatchEvent other) {
    _$v = other as _$StoredMatchEvent;
  }

  @override
  void update(void Function(StoredMatchEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  StoredMatchEvent build() => _build();

  _$StoredMatchEvent _build() {
    _$StoredMatchEvent _$result;
    try {
      _$result = _$v ??
          _$StoredMatchEvent._(
            serverSeq: BuiltValueNullFieldError.checkNotNull(
                serverSeq, r'StoredMatchEvent', 'serverSeq'),
            event: event.build(),
            recordedBy: recordedBy.build(),
            receivedAt: BuiltValueNullFieldError.checkNotNull(
                receivedAt, r'StoredMatchEvent', 'receivedAt'),
            voidedByEventId: voidedByEventId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'event';
        event.build();
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'StoredMatchEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
