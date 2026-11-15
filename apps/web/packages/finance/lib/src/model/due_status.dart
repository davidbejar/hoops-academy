//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'due_status.g.dart';

/// OPEN until paid in full (PAID) or waived (WAIVED); a voided payment makes it OPEN again.
class DueStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OPEN')
  static const DueStatus OPEN = _$OPEN;
  @BuiltValueEnumConst(wireName: r'PAID')
  static const DueStatus PAID = _$PAID;
  @BuiltValueEnumConst(wireName: r'WAIVED')
  static const DueStatus WAIVED = _$WAIVED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DueStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<DueStatus> get serializer => _$dueStatusSerializer;

  const DueStatus._(String name): super(name);

  static BuiltSet<DueStatus> get values => _$values;
  static DueStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DueStatusMixin = Object with _$DueStatusMixin;
