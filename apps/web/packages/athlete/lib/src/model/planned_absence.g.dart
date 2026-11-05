// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_absence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlannedAbsence extends PlannedAbsence {
  @override
  final String playerId;
  @override
  final Date fromDate;
  @override
  final Date toDate;
  @override
  final String? reason;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String id;

  factory _$PlannedAbsence([void Function(PlannedAbsenceBuilder)? updates]) =>
      (PlannedAbsenceBuilder()..update(updates))._build();

  _$PlannedAbsence._(
      {required this.playerId,
      required this.fromDate,
      required this.toDate,
      this.reason,
      required this.recordedBy,
      required this.recordedAt,
      required this.id})
      : super._();
  @override
  PlannedAbsence rebuild(void Function(PlannedAbsenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlannedAbsenceBuilder toBuilder() => PlannedAbsenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlannedAbsence &&
        playerId == other.playerId &&
        fromDate == other.fromDate &&
        toDate == other.toDate &&
        reason == other.reason &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, fromDate.hashCode);
    _$hash = $jc(_$hash, toDate.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlannedAbsence')
          ..add('playerId', playerId)
          ..add('fromDate', fromDate)
          ..add('toDate', toDate)
          ..add('reason', reason)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('id', id))
        .toString();
  }
}

class PlannedAbsenceBuilder
    implements Builder<PlannedAbsence, PlannedAbsenceBuilder> {
  _$PlannedAbsence? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  Date? _fromDate;
  Date? get fromDate => _$this._fromDate;
  set fromDate(Date? fromDate) => _$this._fromDate = fromDate;

  Date? _toDate;
  Date? get toDate => _$this._toDate;
  set toDate(Date? toDate) => _$this._toDate = toDate;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

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

  PlannedAbsenceBuilder() {
    PlannedAbsence._defaults(this);
  }

  PlannedAbsenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _fromDate = $v.fromDate;
      _toDate = $v.toDate;
      _reason = $v.reason;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlannedAbsence other) {
    _$v = other as _$PlannedAbsence;
  }

  @override
  void update(void Function(PlannedAbsenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlannedAbsence build() => _build();

  _$PlannedAbsence _build() {
    _$PlannedAbsence _$result;
    try {
      _$result = _$v ??
          _$PlannedAbsence._(
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlannedAbsence', 'playerId'),
            fromDate: BuiltValueNullFieldError.checkNotNull(
                fromDate, r'PlannedAbsence', 'fromDate'),
            toDate: BuiltValueNullFieldError.checkNotNull(
                toDate, r'PlannedAbsence', 'toDate'),
            reason: reason,
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PlannedAbsence', 'recordedAt'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlannedAbsence', 'id'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlannedAbsence', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
