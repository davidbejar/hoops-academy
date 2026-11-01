// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_attendance.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionAttendance extends SessionAttendance {
  @override
  final String sessionId;
  @override
  final BuiltList<AttendanceEntry> entries;

  factory _$SessionAttendance(
          [void Function(SessionAttendanceBuilder)? updates]) =>
      (SessionAttendanceBuilder()..update(updates))._build();

  _$SessionAttendance._({required this.sessionId, required this.entries})
      : super._();
  @override
  SessionAttendance rebuild(void Function(SessionAttendanceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionAttendanceBuilder toBuilder() =>
      SessionAttendanceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionAttendance &&
        sessionId == other.sessionId &&
        entries == other.entries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, sessionId.hashCode);
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionAttendance')
          ..add('sessionId', sessionId)
          ..add('entries', entries))
        .toString();
  }
}

class SessionAttendanceBuilder
    implements Builder<SessionAttendance, SessionAttendanceBuilder> {
  _$SessionAttendance? _$v;

  String? _sessionId;
  String? get sessionId => _$this._sessionId;
  set sessionId(String? sessionId) => _$this._sessionId = sessionId;

  ListBuilder<AttendanceEntry>? _entries;
  ListBuilder<AttendanceEntry> get entries =>
      _$this._entries ??= ListBuilder<AttendanceEntry>();
  set entries(ListBuilder<AttendanceEntry>? entries) =>
      _$this._entries = entries;

  SessionAttendanceBuilder() {
    SessionAttendance._defaults(this);
  }

  SessionAttendanceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _sessionId = $v.sessionId;
      _entries = $v.entries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionAttendance other) {
    _$v = other as _$SessionAttendance;
  }

  @override
  void update(void Function(SessionAttendanceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionAttendance build() => _build();

  _$SessionAttendance _build() {
    _$SessionAttendance _$result;
    try {
      _$result = _$v ??
          _$SessionAttendance._(
            sessionId: BuiltValueNullFieldError.checkNotNull(
                sessionId, r'SessionAttendance', 'sessionId'),
            entries: entries.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'entries';
        entries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SessionAttendance', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
