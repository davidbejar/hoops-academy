//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_result_status.g.dart';

class MatchEventResultStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const MatchEventResultStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'DUPLICATE')
  static const MatchEventResultStatus DUPLICATE = _$DUPLICATE;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const MatchEventResultStatus REJECTED = _$REJECTED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MatchEventResultStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<MatchEventResultStatus> get serializer => _$matchEventResultStatusSerializer;

  const MatchEventResultStatus._(String name): super(name);

  static BuiltSet<MatchEventResultStatus> get values => _$values;
  static MatchEventResultStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class MatchEventResultStatusMixin = Object with _$MatchEventResultStatusMixin;

