//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fee_cadence.g.dart';

/// MONTHLY = calendar months, QUARTERLY = calendar quarters, SEASON = once per season (decision 93).
class FeeCadence extends EnumClass {

  @BuiltValueEnumConst(wireName: r'MONTHLY')
  static const FeeCadence MONTHLY = _$MONTHLY;
  @BuiltValueEnumConst(wireName: r'QUARTERLY')
  static const FeeCadence QUARTERLY = _$QUARTERLY;
  @BuiltValueEnumConst(wireName: r'SEASON')
  static const FeeCadence SEASON = _$SEASON;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const FeeCadence unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<FeeCadence> get serializer => _$feeCadenceSerializer;

  const FeeCadence._(String name): super(name);

  static BuiltSet<FeeCadence> get values => _$values;
  static FeeCadence valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class FeeCadenceMixin = Object with _$FeeCadenceMixin;
