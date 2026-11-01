// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_absence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlannedAbsence extends PlannedAbsence {
  @override
  final String id;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String playerId;
  @override
  final Date fromDate;
  @override
  final Date toDate;
  @override
  final String? reason;

  factory _$PlannedAbsence([void Function(PlannedAbsenceBuilder)? updates]) =>
      (PlannedAbsenceBuilder()..update(updates))._build();

  _$PlannedAbsence._(
      {required this.id,
      required this.recordedBy,
      required this.recordedAt,
      required this.playerId,
      required this.fromDate,
      required this.toDate,
      this.reason})
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
        id == other.id &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        playerId == other.playerId &&
        fromDate == other.fromDate &&
        toDate == other.toDate &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, fromDate.hashCode);
    _$hash = $jc(_$hash, toDate.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlannedAbsence')
          ..add('id', id)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('playerId', playerId)
          ..add('fromDate', fromDate)
          ..add('toDate', toDate)
          ..add('reason', reason))
        .toString();
  }
}

class PlannedAbsenceBuilder
    implements
        Builder<PlannedAbsence, PlannedAbsenceBuilder>,
        AuditInfoBuilder,
        PlannedAbsenceInputBuilder {
  _$PlannedAbsence? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  Date? _fromDate;
  Date? get fromDate => _$this._fromDate;
  set fromDate(covariant Date? fromDate) => _$this._fromDate = fromDate;

  Date? _toDate;
  Date? get toDate => _$this._toDate;
  set toDate(covariant Date? toDate) => _$this._toDate = toDate;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(covariant String? reason) => _$this._reason = reason;

  PlannedAbsenceBuilder() {
    PlannedAbsence._defaults(this);
  }

  PlannedAbsenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _playerId = $v.playerId;
      _fromDate = $v.fromDate;
      _toDate = $v.toDate;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
// ignore: override_on_non_overriding_method
  void replace(covariant PlannedAbsence other) {
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
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlannedAbsence', 'id'),
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'PlannedAbsence', 'recordedAt'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlannedAbsence', 'playerId'),
            fromDate: BuiltValueNullFieldError.checkNotNull(
                fromDate, r'PlannedAbsence', 'fromDate'),
            toDate: BuiltValueNullFieldError.checkNotNull(
                toDate, r'PlannedAbsence', 'toDate'),
            reason: reason,
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
