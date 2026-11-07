//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'gender_policy.g.dart';

class GenderPolicy extends EnumClass {
  @BuiltValueEnumConst(wireName: r'MALE')
  static const GenderPolicy MALE = _$MALE;
  @BuiltValueEnumConst(wireName: r'FEMALE')
  static const GenderPolicy FEMALE = _$FEMALE;
  @BuiltValueEnumConst(wireName: r'MIXED')
  static const GenderPolicy MIXED = _$MIXED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const GenderPolicy unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<GenderPolicy> get serializer => _$genderPolicySerializer;

  const GenderPolicy._(String name) : super(name);

  static BuiltSet<GenderPolicy> get values => _$values;
  static GenderPolicy valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class GenderPolicyMixin = Object with _$GenderPolicyMixin;
