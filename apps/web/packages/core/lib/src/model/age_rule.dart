//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'age_rule.g.dart';

/// BIRTH_YEAR (default): age = season reference year − birth year. BIRTHDAY: actual age on the evaluation date. 
class AgeRule extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BIRTH_YEAR')
  static const AgeRule BIRTH_YEAR = _$BIRTH_YEAR;
  @BuiltValueEnumConst(wireName: r'BIRTHDAY')
  static const AgeRule BIRTHDAY = _$BIRTHDAY;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AgeRule unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<AgeRule> get serializer => _$ageRuleSerializer;

  const AgeRule._(String name): super(name);

  static BuiltSet<AgeRule> get values => _$values;
  static AgeRule valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AgeRuleMixin = Object with _$AgeRuleMixin;

