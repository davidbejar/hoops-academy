//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_reason.g.dart';

/// Why a player is INELIGIBLE for a team (or why an assignment was invalidated).
class EligibilityReason extends EnumClass {
  @BuiltValueEnumConst(wireName: r'CATEGORY_TOO_LOW')
  static const EligibilityReason CATEGORY_TOO_LOW = _$CATEGORY_TOO_LOW;
  @BuiltValueEnumConst(wireName: r'PLAY_UP_LIMIT_EXCEEDED')
  static const EligibilityReason PLAY_UP_LIMIT_EXCEEDED =
      _$PLAY_UP_LIMIT_EXCEEDED;
  @BuiltValueEnumConst(wireName: r'GENDER_POLICY')
  static const EligibilityReason GENDER_POLICY = _$GENDER_POLICY;
  @BuiltValueEnumConst(wireName: r'MISSING_BIRTH_DATE')
  static const EligibilityReason MISSING_BIRTH_DATE = _$MISSING_BIRTH_DATE;
  @BuiltValueEnumConst(wireName: r'MISSING_GENDER')
  static const EligibilityReason MISSING_GENDER = _$MISSING_GENDER;
  @BuiltValueEnumConst(wireName: r'PLAYER_NOT_ACTIVE')
  static const EligibilityReason PLAYER_NOT_ACTIVE = _$PLAYER_NOT_ACTIVE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const EligibilityReason unknownDefaultOpenApi =
      _$unknownDefaultOpenApi;

  static Serializer<EligibilityReason> get serializer =>
      _$eligibilityReasonSerializer;

  const EligibilityReason._(String name) : super(name);

  static BuiltSet<EligibilityReason> get values => _$values;
  static EligibilityReason valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class EligibilityReasonMixin = Object with _$EligibilityReasonMixin;
