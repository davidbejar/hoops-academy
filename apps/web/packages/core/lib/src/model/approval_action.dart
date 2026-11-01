//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'approval_action.g.dart';

class ApprovalAction extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ADD_PLAYER')
  static const ApprovalAction ADD_PLAYER = _$ADD_PLAYER;
  @BuiltValueEnumConst(wireName: r'WITHDRAW_PLAYER')
  static const ApprovalAction WITHDRAW_PLAYER = _$WITHDRAW_PLAYER;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ApprovalAction unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<ApprovalAction> get serializer => _$approvalActionSerializer;

  const ApprovalAction._(String name): super(name);

  static BuiltSet<ApprovalAction> get values => _$values;
  static ApprovalAction valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ApprovalActionMixin = Object with _$ApprovalActionMixin;

