//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_status.g.dart';

class MatchStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'SCHEDULED')
  static const MatchStatus SCHEDULED = _$SCHEDULED;
  @BuiltValueEnumConst(wireName: r'LIVE')
  static const MatchStatus LIVE = _$LIVE;
  @BuiltValueEnumConst(wireName: r'FINISHED')
  static const MatchStatus FINISHED = _$FINISHED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const MatchStatus CANCELLED = _$CANCELLED;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MatchStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<MatchStatus> get serializer => _$matchStatusSerializer;

  const MatchStatus._(String name): super(name);

  static BuiltSet<MatchStatus> get values => _$values;
  static MatchStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class MatchStatusMixin = Object with _$MatchStatusMixin;

