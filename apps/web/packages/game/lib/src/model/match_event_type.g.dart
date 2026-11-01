// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MatchEventType _$PERIOD_START = const MatchEventType._('PERIOD_START');
const MatchEventType _$PERIOD_END = const MatchEventType._('PERIOD_END');
const MatchEventType _$SUB_IN = const MatchEventType._('SUB_IN');
const MatchEventType _$SUB_OUT = const MatchEventType._('SUB_OUT');
const MatchEventType _$SHOT = const MatchEventType._('SHOT');
const MatchEventType _$ASSIST = const MatchEventType._('ASSIST');
const MatchEventType _$REBOUND = const MatchEventType._('REBOUND');
const MatchEventType _$TURNOVER = const MatchEventType._('TURNOVER');
const MatchEventType _$STEAL = const MatchEventType._('STEAL');
const MatchEventType _$BLOCK = const MatchEventType._('BLOCK');
const MatchEventType _$FOUL = const MatchEventType._('FOUL');
const MatchEventType _$OPPONENT_SCORE =
    const MatchEventType._('OPPONENT_SCORE');
const MatchEventType _$TIMEOUT = const MatchEventType._('TIMEOUT');
const MatchEventType _$VOID = const MatchEventType._('VOID');
const MatchEventType _$NOTE = const MatchEventType._('NOTE');
const MatchEventType _$unknownDefaultOpenApi =
    const MatchEventType._('unknownDefaultOpenApi');

MatchEventType _$valueOf(String name) {
  switch (name) {
    case 'PERIOD_START':
      return _$PERIOD_START;
    case 'PERIOD_END':
      return _$PERIOD_END;
    case 'SUB_IN':
      return _$SUB_IN;
    case 'SUB_OUT':
      return _$SUB_OUT;
    case 'SHOT':
      return _$SHOT;
    case 'ASSIST':
      return _$ASSIST;
    case 'REBOUND':
      return _$REBOUND;
    case 'TURNOVER':
      return _$TURNOVER;
    case 'STEAL':
      return _$STEAL;
    case 'BLOCK':
      return _$BLOCK;
    case 'FOUL':
      return _$FOUL;
    case 'OPPONENT_SCORE':
      return _$OPPONENT_SCORE;
    case 'TIMEOUT':
      return _$TIMEOUT;
    case 'VOID':
      return _$VOID;
    case 'NOTE':
      return _$NOTE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<MatchEventType> _$values =
    BuiltSet<MatchEventType>(const <MatchEventType>[
  _$PERIOD_START,
  _$PERIOD_END,
  _$SUB_IN,
  _$SUB_OUT,
  _$SHOT,
  _$ASSIST,
  _$REBOUND,
  _$TURNOVER,
  _$STEAL,
  _$BLOCK,
  _$FOUL,
  _$OPPONENT_SCORE,
  _$TIMEOUT,
  _$VOID,
  _$NOTE,
  _$unknownDefaultOpenApi,
]);

class _$MatchEventTypeMeta {
  const _$MatchEventTypeMeta();
  MatchEventType get PERIOD_START => _$PERIOD_START;
  MatchEventType get PERIOD_END => _$PERIOD_END;
  MatchEventType get SUB_IN => _$SUB_IN;
  MatchEventType get SUB_OUT => _$SUB_OUT;
  MatchEventType get SHOT => _$SHOT;
  MatchEventType get ASSIST => _$ASSIST;
  MatchEventType get REBOUND => _$REBOUND;
  MatchEventType get TURNOVER => _$TURNOVER;
  MatchEventType get STEAL => _$STEAL;
  MatchEventType get BLOCK => _$BLOCK;
  MatchEventType get FOUL => _$FOUL;
  MatchEventType get OPPONENT_SCORE => _$OPPONENT_SCORE;
  MatchEventType get TIMEOUT => _$TIMEOUT;
  MatchEventType get VOID => _$VOID;
  MatchEventType get NOTE => _$NOTE;
  MatchEventType get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  MatchEventType valueOf(String name) => _$valueOf(name);
  BuiltSet<MatchEventType> get values => _$values;
}

abstract class _$MatchEventTypeMixin {
  // ignore: non_constant_identifier_names
  _$MatchEventTypeMeta get MatchEventType => const _$MatchEventTypeMeta();
}

Serializer<MatchEventType> _$matchEventTypeSerializer =
    _$MatchEventTypeSerializer();

class _$MatchEventTypeSerializer
    implements PrimitiveSerializer<MatchEventType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PERIOD_START': 'PERIOD_START',
    'PERIOD_END': 'PERIOD_END',
    'SUB_IN': 'SUB_IN',
    'SUB_OUT': 'SUB_OUT',
    'SHOT': 'SHOT',
    'ASSIST': 'ASSIST',
    'REBOUND': 'REBOUND',
    'TURNOVER': 'TURNOVER',
    'STEAL': 'STEAL',
    'BLOCK': 'BLOCK',
    'FOUL': 'FOUL',
    'OPPONENT_SCORE': 'OPPONENT_SCORE',
    'TIMEOUT': 'TIMEOUT',
    'VOID': 'VOID',
    'NOTE': 'NOTE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PERIOD_START': 'PERIOD_START',
    'PERIOD_END': 'PERIOD_END',
    'SUB_IN': 'SUB_IN',
    'SUB_OUT': 'SUB_OUT',
    'SHOT': 'SHOT',
    'ASSIST': 'ASSIST',
    'REBOUND': 'REBOUND',
    'TURNOVER': 'TURNOVER',
    'STEAL': 'STEAL',
    'BLOCK': 'BLOCK',
    'FOUL': 'FOUL',
    'OPPONENT_SCORE': 'OPPONENT_SCORE',
    'TIMEOUT': 'TIMEOUT',
    'VOID': 'VOID',
    'NOTE': 'NOTE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MatchEventType];
  @override
  final String wireName = 'MatchEventType';

  @override
  Object serialize(Serializers serializers, MatchEventType object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MatchEventType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MatchEventType.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
