//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_case_resolution.g.dart';

class EligibilityCaseResolution extends EnumClass {

  @BuiltValueEnumConst(wireName: r'REASSIGNED')
  static const EligibilityCaseResolution REASSIGNED = _$REASSIGNED;
  @BuiltValueEnumConst(wireName: r'REMOVED_FROM_TEAM')
  static const EligibilityCaseResolution REMOVED_FROM_TEAM = _$REMOVED_FROM_TEAM;
  @BuiltValueEnumConst(wireName: r'DISMISSED')
  static const EligibilityCaseResolution DISMISSED = _$DISMISSED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const EligibilityCaseResolution unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<EligibilityCaseResolution> get serializer => _$eligibilityCaseResolutionSerializer;

  const EligibilityCaseResolution._(String name): super(name);

  static BuiltSet<EligibilityCaseResolution> get values => _$values;
  static EligibilityCaseResolution valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class EligibilityCaseResolutionMixin = Object with _$EligibilityCaseResolutionMixin;

