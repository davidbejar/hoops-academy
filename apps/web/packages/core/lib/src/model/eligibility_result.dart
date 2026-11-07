//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_result.g.dart';

class EligibilityResult extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ELIGIBLE')
  static const EligibilityResult ELIGIBLE = _$ELIGIBLE;
  @BuiltValueEnumConst(wireName: r'PLAY_UP')
  static const EligibilityResult PLAY_UP = _$PLAY_UP;
  @BuiltValueEnumConst(wireName: r'INELIGIBLE')
  static const EligibilityResult INELIGIBLE = _$INELIGIBLE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const EligibilityResult unknownDefaultOpenApi =
      _$unknownDefaultOpenApi;

  static Serializer<EligibilityResult> get serializer =>
      _$eligibilityResultSerializer;

  const EligibilityResult._(String name) : super(name);

  static BuiltSet<EligibilityResult> get values => _$values;
  static EligibilityResult valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class EligibilityResultMixin = Object with _$EligibilityResultMixin;
