//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'approval_status.g.dart';

class ApprovalStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const ApprovalStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'APPROVED')
  static const ApprovalStatus APPROVED = _$APPROVED;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const ApprovalStatus REJECTED = _$REJECTED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const ApprovalStatus CANCELLED = _$CANCELLED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ApprovalStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ApprovalStatus> get serializer => _$approvalStatusSerializer;

  const ApprovalStatus._(String name): super(name);

  static BuiltSet<ApprovalStatus> get values => _$values;
  static ApprovalStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ApprovalStatusMixin = Object with _$ApprovalStatusMixin;

