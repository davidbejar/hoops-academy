//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_event_type.g.dart';

class MatchEventType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PERIOD_START')
  static const MatchEventType PERIOD_START = _$PERIOD_START;
  @BuiltValueEnumConst(wireName: r'PERIOD_END')
  static const MatchEventType PERIOD_END = _$PERIOD_END;
  @BuiltValueEnumConst(wireName: r'SUB_IN')
  static const MatchEventType SUB_IN = _$SUB_IN;
  @BuiltValueEnumConst(wireName: r'SUB_OUT')
  static const MatchEventType SUB_OUT = _$SUB_OUT;
  @BuiltValueEnumConst(wireName: r'SHOT')
  static const MatchEventType SHOT = _$SHOT;
  @BuiltValueEnumConst(wireName: r'ASSIST')
  static const MatchEventType ASSIST = _$ASSIST;
  @BuiltValueEnumConst(wireName: r'REBOUND')
  static const MatchEventType REBOUND = _$REBOUND;
  @BuiltValueEnumConst(wireName: r'TURNOVER')
  static const MatchEventType TURNOVER = _$TURNOVER;
  @BuiltValueEnumConst(wireName: r'STEAL')
  static const MatchEventType STEAL = _$STEAL;
  @BuiltValueEnumConst(wireName: r'BLOCK')
  static const MatchEventType BLOCK = _$BLOCK;
  @BuiltValueEnumConst(wireName: r'FOUL')
  static const MatchEventType FOUL = _$FOUL;
  @BuiltValueEnumConst(wireName: r'OPPONENT_SCORE')
  static const MatchEventType OPPONENT_SCORE = _$OPPONENT_SCORE;
  @BuiltValueEnumConst(wireName: r'TIMEOUT')
  static const MatchEventType TIMEOUT = _$TIMEOUT;
  @BuiltValueEnumConst(wireName: r'VOID')
  static const MatchEventType VOID = _$VOID;
  @BuiltValueEnumConst(wireName: r'NOTE')
  static const MatchEventType NOTE = _$NOTE;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const MatchEventType unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<MatchEventType> get serializer => _$matchEventTypeSerializer;

  const MatchEventType._(String name): super(name);

  static BuiltSet<MatchEventType> get values => _$values;
  static MatchEventType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class MatchEventTypeMixin = Object with _$MatchEventTypeMixin;

