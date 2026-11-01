//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'attendance_status.g.dart';

class AttendanceStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PRESENT')
  static const AttendanceStatus PRESENT = _$PRESENT;
  @BuiltValueEnumConst(wireName: r'LATE')
  static const AttendanceStatus LATE = _$LATE;
  @BuiltValueEnumConst(wireName: r'ABSENT')
  static const AttendanceStatus ABSENT = _$ABSENT;
  @BuiltValueEnumConst(wireName: r'EXCUSED')
  static const AttendanceStatus EXCUSED = _$EXCUSED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AttendanceStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<AttendanceStatus> get serializer => _$attendanceStatusSerializer;

  const AttendanceStatus._(String name): super(name);

  static BuiltSet<AttendanceStatus> get values => _$values;
  static AttendanceStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AttendanceStatusMixin = Object with _$AttendanceStatusMixin;

