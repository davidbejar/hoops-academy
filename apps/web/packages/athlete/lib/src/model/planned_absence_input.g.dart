// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_absence_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class PlannedAbsenceInputBuilder {
  void replace(PlannedAbsenceInput other);
  void update(void Function(PlannedAbsenceInputBuilder) updates);
  String? get playerId;
  set playerId(String? playerId);

  Date? get fromDate;
  set fromDate(Date? fromDate);

  Date? get toDate;
  set toDate(Date? toDate);

  String? get reason;
  set reason(String? reason);
}

class _$$PlannedAbsenceInput extends $PlannedAbsenceInput {
  @override
  final String playerId;
  @override
  final Date fromDate;
  @override
  final Date toDate;
  @override
  final String? reason;

  factory _$$PlannedAbsenceInput(
          [void Function($PlannedAbsenceInputBuilder)? updates]) =>
      ($PlannedAbsenceInputBuilder()..update(updates))._build();

  _$$PlannedAbsenceInput._(
      {required this.playerId,
      required this.fromDate,
      required this.toDate,
      this.reason})
      : super._();
  @override
  $PlannedAbsenceInput rebuild(
          void Function($PlannedAbsenceInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $PlannedAbsenceInputBuilder toBuilder() =>
      $PlannedAbsenceInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $PlannedAbsenceInput &&
        playerId == other.playerId &&
        fromDate == other.fromDate &&
        toDate == other.toDate &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, fromDate.hashCode);
    _$hash = $jc(_$hash, toDate.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$PlannedAbsenceInput')
          ..add('playerId', playerId)
          ..add('fromDate', fromDate)
          ..add('toDate', toDate)
          ..add('reason', reason))
        .toString();
  }
}

class $PlannedAbsenceInputBuilder
    implements
        Builder<$PlannedAbsenceInput, $PlannedAbsenceInputBuilder>,
        PlannedAbsenceInputBuilder {
  _$$PlannedAbsenceInput? _$v;

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

  $PlannedAbsenceInputBuilder() {
    $PlannedAbsenceInput._defaults(this);
  }

  $PlannedAbsenceInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _fromDate = $v.fromDate;
      _toDate = $v.toDate;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $PlannedAbsenceInput other) {
    _$v = other as _$$PlannedAbsenceInput;
  }

  @override
  void update(void Function($PlannedAbsenceInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $PlannedAbsenceInput build() => _build();

  _$$PlannedAbsenceInput _build() {
    final _$result = _$v ??
        _$$PlannedAbsenceInput._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'$PlannedAbsenceInput', 'playerId'),
          fromDate: BuiltValueNullFieldError.checkNotNull(
              fromDate, r'$PlannedAbsenceInput', 'fromDate'),
          toDate: BuiltValueNullFieldError.checkNotNull(
              toDate, r'$PlannedAbsenceInput', 'toDate'),
          reason: reason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
