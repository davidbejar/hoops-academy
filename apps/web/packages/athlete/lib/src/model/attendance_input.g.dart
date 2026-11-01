// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AttendanceInput extends AttendanceInput {
  @override
  final String playerId;
  @override
  final AttendanceStatus status;
  @override
  final int? minutesLate;
  @override
  final String? note;

  factory _$AttendanceInput([void Function(AttendanceInputBuilder)? updates]) =>
      (AttendanceInputBuilder()..update(updates))._build();

  _$AttendanceInput._(
      {required this.playerId,
      required this.status,
      this.minutesLate,
      this.note})
      : super._();
  @override
  AttendanceInput rebuild(void Function(AttendanceInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AttendanceInputBuilder toBuilder() => AttendanceInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AttendanceInput &&
        playerId == other.playerId &&
        status == other.status &&
        minutesLate == other.minutesLate &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, minutesLate.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AttendanceInput')
          ..add('playerId', playerId)
          ..add('status', status)
          ..add('minutesLate', minutesLate)
          ..add('note', note))
        .toString();
  }
}

class AttendanceInputBuilder
    implements Builder<AttendanceInput, AttendanceInputBuilder> {
  _$AttendanceInput? _$v;

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

  AttendanceInputBuilder() {
    AttendanceInput._defaults(this);
  }

  AttendanceInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _status = $v.status;
      _minutesLate = $v.minutesLate;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AttendanceInput other) {
    _$v = other as _$AttendanceInput;
  }

  @override
  void update(void Function(AttendanceInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AttendanceInput build() => _build();

  _$AttendanceInput _build() {
    final _$result = _$v ??
        _$AttendanceInput._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'AttendanceInput', 'playerId'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'AttendanceInput', 'status'),
          minutesLate: minutesLate,
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
