//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'eligibility_case_status.g.dart';

class EligibilityCaseStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'OPEN')
  static const EligibilityCaseStatus OPEN = _$OPEN;
  @BuiltValueEnumConst(wireName: r'RESOLVED')
  static const EligibilityCaseStatus RESOLVED = _$RESOLVED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const EligibilityCaseStatus unknownDefaultOpenApi =
      _$unknownDefaultOpenApi;

  static Serializer<EligibilityCaseStatus> get serializer =>
      _$eligibilityCaseStatusSerializer;

  const EligibilityCaseStatus._(String name) : super(name);

  static BuiltSet<EligibilityCaseStatus> get values => _$values;
  static EligibilityCaseStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class EligibilityCaseStatusMixin = Object
    with _$EligibilityCaseStatusMixin;
