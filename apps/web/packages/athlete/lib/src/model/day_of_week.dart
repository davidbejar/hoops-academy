//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'day_of_week.g.dart';

class DayOfWeek extends EnumClass {

  @BuiltValueEnumConst(wireName: r'MONDAY')
  static const DayOfWeek MONDAY = _$MONDAY;
  @BuiltValueEnumConst(wireName: r'TUESDAY')
  static const DayOfWeek TUESDAY = _$TUESDAY;
  @BuiltValueEnumConst(wireName: r'WEDNESDAY')
  static const DayOfWeek WEDNESDAY = _$WEDNESDAY;
  @BuiltValueEnumConst(wireName: r'THURSDAY')
  static const DayOfWeek THURSDAY = _$THURSDAY;
  @BuiltValueEnumConst(wireName: r'FRIDAY')
  static const DayOfWeek FRIDAY = _$FRIDAY;
  @BuiltValueEnumConst(wireName: r'SATURDAY')
  static const DayOfWeek SATURDAY = _$SATURDAY;
  @BuiltValueEnumConst(wireName: r'SUNDAY')
  static const DayOfWeek SUNDAY = _$SUNDAY;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DayOfWeek unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<DayOfWeek> get serializer => _$dayOfWeekSerializer;

  const DayOfWeek._(String name): super(name);

  static BuiltSet<DayOfWeek> get values => _$values;
  static DayOfWeek valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DayOfWeekMixin = Object with _$DayOfWeekMixin;

