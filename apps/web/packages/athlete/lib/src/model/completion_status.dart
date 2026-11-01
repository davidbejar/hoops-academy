//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'completion_status.g.dart';

class CompletionStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DONE')
  static const CompletionStatus DONE = _$DONE;
  @BuiltValueEnumConst(wireName: r'PARTIAL')
  static const CompletionStatus PARTIAL = _$PARTIAL;
  @BuiltValueEnumConst(wireName: r'NOT_DONE')
  static const CompletionStatus NOT_DONE = _$NOT_DONE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const CompletionStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<CompletionStatus> get serializer => _$completionStatusSerializer;

  const CompletionStatus._(String name): super(name);

  static BuiltSet<CompletionStatus> get values => _$values;
  static CompletionStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class CompletionStatusMixin = Object with _$CompletionStatusMixin;

