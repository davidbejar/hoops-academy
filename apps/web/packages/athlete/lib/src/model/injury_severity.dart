//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'injury_severity.g.dart';

class InjurySeverity extends EnumClass {

  @BuiltValueEnumConst(wireName: r'MINOR')
  static const InjurySeverity MINOR = _$MINOR;
  @BuiltValueEnumConst(wireName: r'MODERATE')
  static const InjurySeverity MODERATE = _$MODERATE;
  @BuiltValueEnumConst(wireName: r'SEVERE')
  static const InjurySeverity SEVERE = _$SEVERE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const InjurySeverity unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<InjurySeverity> get serializer => _$injurySeveritySerializer;

  const InjurySeverity._(String name): super(name);

  static BuiltSet<InjurySeverity> get values => _$values;
  static InjurySeverity valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class InjurySeverityMixin = Object with _$InjurySeverityMixin;

