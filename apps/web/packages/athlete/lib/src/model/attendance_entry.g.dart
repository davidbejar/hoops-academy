// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_entry.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AttendanceEntry extends AttendanceEntry {
  @override
  final String playerId;
  @override
  final AttendanceStatus? status;
  @override
  final int? minutesLate;
  @override
  final String? note;
  @override
  final bool expectedAbsent;
  @override
  final String? plannedAbsenceId;
  @override
  final String? unavailableInjuryId;
  @override
  final PersonRef? recordedBy;
  @override
  final DateTime? recordedAt;

  factory _$AttendanceEntry([void Function(AttendanceEntryBuilder)? updates]) =>
      (AttendanceEntryBuilder()..update(updates))._build();

  _$AttendanceEntry._(
      {required this.playerId,
      this.status,
      this.minutesLate,
      this.note,
      required this.expectedAbsent,
      this.plannedAbsenceId,
      this.unavailableInjuryId,
      this.recordedBy,
      this.recordedAt})
      : super._();
  @override
  AttendanceEntry rebuild(void Function(AttendanceEntryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AttendanceEntryBuilder toBuilder() => AttendanceEntryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AttendanceEntry &&
        playerId == other.playerId &&
        status == other.status &&
        minutesLate == other.minutesLate &&
        note == other.note &&
        expectedAbsent == other.expectedAbsent &&
        plannedAbsenceId == other.plannedAbsenceId &&
        unavailableInjuryId == other.unavailableInjuryId &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, minutesLate.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, expectedAbsent.hashCode);
    _$hash = $jc(_$hash, plannedAbsenceId.hashCode);
    _$hash = $jc(_$hash, unavailableInjuryId.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AttendanceEntry')
          ..add('playerId', playerId)
          ..add('status', status)
          ..add('minutesLate', minutesLate)
          ..add('note', note)
          ..add('expectedAbsent', expectedAbsent)
          ..add('plannedAbsenceId', plannedAbsenceId)
          ..add('unavailableInjuryId', unavailableInjuryId)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class AttendanceEntryBuilder
    implements Builder<AttendanceEntry, AttendanceEntryBuilder> {
  _$AttendanceEntry? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  AttendanceStatus? _status;
  AttendanceStatus? get status => _$this._status;
  set status(AttendanceStatus? status) => _$this._status = status;

  int? _minutesLate;
  int? get minutesLate => _$this._minutesLate;
  set minutesLate(int? minutesLate) => _$this._minutesLate = minutesLate;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  bool? _expectedAbsent;
  bool? get expectedAbsent => _$this._expectedAbsent;
  set expectedAbsent(bool? expectedAbsent) =>
      _$this._expectedAbsent = expectedAbsent;

  String? _plannedAbsenceId;
  String? get plannedAbsenceId => _$this._plannedAbsenceId;
  set plannedAbsenceId(String? plannedAbsenceId) =>
      _$this._plannedAbsenceId = plannedAbsenceId;

  String? _unavailableInjuryId;
  String? get unavailableInjuryId => _$this._unavailableInjuryId;
  set unavailableInjuryId(String? unavailableInjuryId) =>
      _$this._unavailableInjuryId = unavailableInjuryId;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(DateTime? recordedAt) => _$this._recordedAt = recordedAt;

  AttendanceEntryBuilder() {
    AttendanceEntry._defaults(this);
  }

  AttendanceEntryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _status = $v.status;
      _minutesLate = $v.minutesLate;
      _note = $v.note;
      _expectedAbsent = $v.expectedAbsent;
      _plannedAbsenceId = $v.plannedAbsenceId;
      _unavailableInjuryId = $v.unavailableInjuryId;
      _recordedBy = $v.recordedBy?.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AttendanceEntry other) {
    _$v = other as _$AttendanceEntry;
  }

  @override
  void update(void Function(AttendanceEntryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AttendanceEntry build() => _build();

  _$AttendanceEntry _build() {
    _$AttendanceEntry _$result;
    try {
      _$result = _$v ??
          _$AttendanceEntry._(
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'AttendanceEntry', 'playerId'),
            status: status,
            minutesLate: minutesLate,
            note: note,
            expectedAbsent: BuiltValueNullFieldError.checkNotNull(
                expectedAbsent, r'AttendanceEntry', 'expectedAbsent'),
            plannedAbsenceId: plannedAbsenceId,
            unavailableInjuryId: unavailableInjuryId,
            recordedBy: _recordedBy?.build(),
            recordedAt: recordedAt,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        _recordedBy?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AttendanceEntry', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
