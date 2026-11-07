// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_rejection_reason.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MatchEventRejectionReason _$SCHEMA_INVALID =
    const MatchEventRejectionReason._('SCHEMA_INVALID');
const MatchEventRejectionReason _$NOT_AUTHORIZED =
    const MatchEventRejectionReason._('NOT_AUTHORIZED');
const MatchEventRejectionReason _$MATCH_CANCELLED =
    const MatchEventRejectionReason._('MATCH_CANCELLED');
const MatchEventRejectionReason _$CLIENT_SEQ_CONFLICT =
    const MatchEventRejectionReason._('CLIENT_SEQ_CONFLICT');
const MatchEventRejectionReason _$EVENT_ID_REUSED =
    const MatchEventRejectionReason._('EVENT_ID_REUSED');
const MatchEventRejectionReason _$MATCH_NOT_STARTED =
    const MatchEventRejectionReason._('MATCH_NOT_STARTED');
const MatchEventRejectionReason _$SEASON_ENDED =
    const MatchEventRejectionReason._('SEASON_ENDED');
const MatchEventRejectionReason _$unknownDefaultOpenApi =
    const MatchEventRejectionReason._('unknownDefaultOpenApi');

MatchEventRejectionReason _$valueOf(String name) {
  switch (name) {
    case 'SCHEMA_INVALID':
      return _$SCHEMA_INVALID;
    case 'NOT_AUTHORIZED':
      return _$NOT_AUTHORIZED;
    case 'MATCH_CANCELLED':
      return _$MATCH_CANCELLED;
    case 'CLIENT_SEQ_CONFLICT':
      return _$CLIENT_SEQ_CONFLICT;
    case 'EVENT_ID_REUSED':
      return _$EVENT_ID_REUSED;
    case 'MATCH_NOT_STARTED':
      return _$MATCH_NOT_STARTED;
    case 'SEASON_ENDED':
      return _$SEASON_ENDED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<MatchEventRejectionReason> _$values =
    BuiltSet<MatchEventRejectionReason>(const <MatchEventRejectionReason>[
  _$SCHEMA_INVALID,
  _$NOT_AUTHORIZED,
  _$MATCH_CANCELLED,
  _$CLIENT_SEQ_CONFLICT,
  _$EVENT_ID_REUSED,
  _$MATCH_NOT_STARTED,
  _$SEASON_ENDED,
  _$unknownDefaultOpenApi,
]);

class _$MatchEventRejectionReasonMeta {
  const _$MatchEventRejectionReasonMeta();
  MatchEventRejectionReason get SCHEMA_INVALID => _$SCHEMA_INVALID;
  MatchEventRejectionReason get NOT_AUTHORIZED => _$NOT_AUTHORIZED;
  MatchEventRejectionReason get MATCH_CANCELLED => _$MATCH_CANCELLED;
  MatchEventRejectionReason get CLIENT_SEQ_CONFLICT => _$CLIENT_SEQ_CONFLICT;
  MatchEventRejectionReason get EVENT_ID_REUSED => _$EVENT_ID_REUSED;
  MatchEventRejectionReason get MATCH_NOT_STARTED => _$MATCH_NOT_STARTED;
  MatchEventRejectionReason get SEASON_ENDED => _$SEASON_ENDED;
  MatchEventRejectionReason get unknownDefaultOpenApi =>
      _$unknownDefaultOpenApi;
  MatchEventRejectionReason valueOf(String name) => _$valueOf(name);
  BuiltSet<MatchEventRejectionReason> get values => _$values;
}

abstract class _$MatchEventRejectionReasonMixin {
  // ignore: non_constant_identifier_names
  _$MatchEventRejectionReasonMeta get MatchEventRejectionReason =>
      const _$MatchEventRejectionReasonMeta();
}

Serializer<MatchEventRejectionReason> _$matchEventRejectionReasonSerializer =
    _$MatchEventRejectionReasonSerializer();

class _$MatchEventRejectionReasonSerializer
    implements PrimitiveSerializer<MatchEventRejectionReason> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'SCHEMA_INVALID': 'SCHEMA_INVALID',
    'NOT_AUTHORIZED': 'NOT_AUTHORIZED',
    'MATCH_CANCELLED': 'MATCH_CANCELLED',
    'CLIENT_SEQ_CONFLICT': 'CLIENT_SEQ_CONFLICT',
    'EVENT_ID_REUSED': 'EVENT_ID_REUSED',
    'MATCH_NOT_STARTED': 'MATCH_NOT_STARTED',
    'SEASON_ENDED': 'SEASON_ENDED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'SCHEMA_INVALID': 'SCHEMA_INVALID',
    'NOT_AUTHORIZED': 'NOT_AUTHORIZED',
    'MATCH_CANCELLED': 'MATCH_CANCELLED',
    'CLIENT_SEQ_CONFLICT': 'CLIENT_SEQ_CONFLICT',
    'EVENT_ID_REUSED': 'EVENT_ID_REUSED',
    'MATCH_NOT_STARTED': 'MATCH_NOT_STARTED',
    'SEASON_ENDED': 'SEASON_ENDED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MatchEventRejectionReason];
  @override
  final String wireName = 'MatchEventRejectionReason';

  @override
  Object serialize(Serializers serializers, MatchEventRejectionReason object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MatchEventRejectionReason deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MatchEventRejectionReason.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
