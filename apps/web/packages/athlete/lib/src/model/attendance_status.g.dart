// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AttendanceStatus _$PRESENT = const AttendanceStatus._('PRESENT');
const AttendanceStatus _$LATE = const AttendanceStatus._('LATE');
const AttendanceStatus _$ABSENT = const AttendanceStatus._('ABSENT');
const AttendanceStatus _$EXCUSED = const AttendanceStatus._('EXCUSED');
const AttendanceStatus _$unknownDefaultOpenApi =
    const AttendanceStatus._('unknownDefaultOpenApi');

AttendanceStatus _$valueOf(String name) {
  switch (name) {
    case 'PRESENT':
      return _$PRESENT;
    case 'LATE':
      return _$LATE;
    case 'ABSENT':
      return _$ABSENT;
    case 'EXCUSED':
      return _$EXCUSED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AttendanceStatus> _$values =
    BuiltSet<AttendanceStatus>(const <AttendanceStatus>[
  _$PRESENT,
  _$LATE,
  _$ABSENT,
  _$EXCUSED,
  _$unknownDefaultOpenApi,
]);

class _$AttendanceStatusMeta {
  const _$AttendanceStatusMeta();
  AttendanceStatus get PRESENT => _$PRESENT;
  AttendanceStatus get LATE => _$LATE;
  AttendanceStatus get ABSENT => _$ABSENT;
  AttendanceStatus get EXCUSED => _$EXCUSED;
  AttendanceStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AttendanceStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<AttendanceStatus> get values => _$values;
}

abstract class _$AttendanceStatusMixin {
  // ignore: non_constant_identifier_names
  _$AttendanceStatusMeta get AttendanceStatus => const _$AttendanceStatusMeta();
}

Serializer<AttendanceStatus> _$attendanceStatusSerializer =
    _$AttendanceStatusSerializer();

class _$AttendanceStatusSerializer
    implements PrimitiveSerializer<AttendanceStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PRESENT': 'PRESENT',
    'LATE': 'LATE',
    'ABSENT': 'ABSENT',
    'EXCUSED': 'EXCUSED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PRESENT': 'PRESENT',
    'LATE': 'LATE',
    'ABSENT': 'ABSENT',
    'EXCUSED': 'EXCUSED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AttendanceStatus];
  @override
  final String wireName = 'AttendanceStatus';

  @override
  Object serialize(Serializers serializers, AttendanceStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AttendanceStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AttendanceStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
