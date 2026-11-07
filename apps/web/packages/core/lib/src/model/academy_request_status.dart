//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'academy_request_status.g.dart';

class AcademyRequestStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'PENDING')
  static const AcademyRequestStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const AcademyRequestStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const AcademyRequestStatus REJECTED = _$REJECTED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const AcademyRequestStatus unknownDefaultOpenApi =
      _$unknownDefaultOpenApi;

  static Serializer<AcademyRequestStatus> get serializer =>
      _$academyRequestStatusSerializer;

  const AcademyRequestStatus._(String name) : super(name);

  static BuiltSet<AcademyRequestStatus> get values => _$values;
  static AcademyRequestStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AcademyRequestStatusMixin = Object
    with _$AcademyRequestStatusMixin;
