// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_attendance_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RecordAttendanceRequest extends RecordAttendanceRequest {
  @override
  final BuiltList<AttendanceInput> entries;

  factory _$RecordAttendanceRequest(
          [void Function(RecordAttendanceRequestBuilder)? updates]) =>
      (RecordAttendanceRequestBuilder()..update(updates))._build();

  _$RecordAttendanceRequest._({required this.entries}) : super._();
  @override
  RecordAttendanceRequest rebuild(
          void Function(RecordAttendanceRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecordAttendanceRequestBuilder toBuilder() =>
      RecordAttendanceRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RecordAttendanceRequest && entries == other.entries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RecordAttendanceRequest')
          ..add('entries', entries))
        .toString();
  }
}

class RecordAttendanceRequestBuilder
    implements
        Builder<RecordAttendanceRequest, RecordAttendanceRequestBuilder> {
  _$RecordAttendanceRequest? _$v;

  ListBuilder<AttendanceInput>? _entries;
  ListBuilder<AttendanceInput> get entries =>
      _$this._entries ??= ListBuilder<AttendanceInput>();
  set entries(ListBuilder<AttendanceInput>? entries) =>
      _$this._entries = entries;

  RecordAttendanceRequestBuilder() {
    RecordAttendanceRequest._defaults(this);
  }

  RecordAttendanceRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entries = $v.entries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RecordAttendanceRequest other) {
    _$v = other as _$RecordAttendanceRequest;
  }

  @override
  void update(void Function(RecordAttendanceRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RecordAttendanceRequest build() => _build();

  _$RecordAttendanceRequest _build() {
    _$RecordAttendanceRequest _$result;
    try {
      _$result = _$v ??
          _$RecordAttendanceRequest._(
            entries: entries.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'entries';
        entries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RecordAttendanceRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
