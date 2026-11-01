// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_planned_absence_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePlannedAbsenceRequest extends UpdatePlannedAbsenceRequest {
  @override
  final Date? fromDate;
  @override
  final Date? toDate;
  @override
  final String? reason;

  factory _$UpdatePlannedAbsenceRequest(
          [void Function(UpdatePlannedAbsenceRequestBuilder)? updates]) =>
      (UpdatePlannedAbsenceRequestBuilder()..update(updates))._build();

  _$UpdatePlannedAbsenceRequest._({this.fromDate, this.toDate, this.reason})
      : super._();
  @override
  UpdatePlannedAbsenceRequest rebuild(
          void Function(UpdatePlannedAbsenceRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePlannedAbsenceRequestBuilder toBuilder() =>
      UpdatePlannedAbsenceRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePlannedAbsenceRequest &&
        fromDate == other.fromDate &&
        toDate == other.toDate &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fromDate.hashCode);
    _$hash = $jc(_$hash, toDate.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePlannedAbsenceRequest')
          ..add('fromDate', fromDate)
          ..add('toDate', toDate)
          ..add('reason', reason))
        .toString();
  }
}

class UpdatePlannedAbsenceRequestBuilder
    implements
        Builder<UpdatePlannedAbsenceRequest,
            UpdatePlannedAbsenceRequestBuilder> {
  _$UpdatePlannedAbsenceRequest? _$v;

  Date? _fromDate;
  Date? get fromDate => _$this._fromDate;
  set fromDate(Date? fromDate) => _$this._fromDate = fromDate;

  Date? _toDate;
  Date? get toDate => _$this._toDate;
  set toDate(Date? toDate) => _$this._toDate = toDate;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  UpdatePlannedAbsenceRequestBuilder() {
    UpdatePlannedAbsenceRequest._defaults(this);
  }

  UpdatePlannedAbsenceRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fromDate = $v.fromDate;
      _toDate = $v.toDate;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePlannedAbsenceRequest other) {
    _$v = other as _$UpdatePlannedAbsenceRequest;
  }

  @override
  void update(void Function(UpdatePlannedAbsenceRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePlannedAbsenceRequest build() => _build();

  _$UpdatePlannedAbsenceRequest _build() {
    final _$result = _$v ??
        _$UpdatePlannedAbsenceRequest._(
          fromDate: fromDate,
          toDate: toDate,
          reason: reason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
