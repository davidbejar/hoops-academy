// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MatchStatus _$SCHEDULED = const MatchStatus._('SCHEDULED');
const MatchStatus _$LIVE = const MatchStatus._('LIVE');
const MatchStatus _$FINISHED = const MatchStatus._('FINISHED');
const MatchStatus _$CANCELLED = const MatchStatus._('CANCELLED');
const MatchStatus _$unknownDefaultOpenApi =
    const MatchStatus._('unknownDefaultOpenApi');

MatchStatus _$valueOf(String name) {
  switch (name) {
    case 'SCHEDULED':
      return _$SCHEDULED;
    case 'LIVE':
      return _$LIVE;
    case 'FINISHED':
      return _$FINISHED;
    case 'CANCELLED':
      return _$CANCELLED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<MatchStatus> _$values =
    BuiltSet<MatchStatus>(const <MatchStatus>[
  _$SCHEDULED,
  _$LIVE,
  _$FINISHED,
  _$CANCELLED,
  _$unknownDefaultOpenApi,
]);

class _$MatchStatusMeta {
  const _$MatchStatusMeta();
  MatchStatus get SCHEDULED => _$SCHEDULED;
  MatchStatus get LIVE => _$LIVE;
  MatchStatus get FINISHED => _$FINISHED;
  MatchStatus get CANCELLED => _$CANCELLED;
  MatchStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  MatchStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<MatchStatus> get values => _$values;
}

abstract class _$MatchStatusMixin {
  // ignore: non_constant_identifier_names
  _$MatchStatusMeta get MatchStatus => const _$MatchStatusMeta();
}

Serializer<MatchStatus> _$matchStatusSerializer = _$MatchStatusSerializer();

class _$MatchStatusSerializer implements PrimitiveSerializer<MatchStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'SCHEDULED': 'SCHEDULED',
    'LIVE': 'LIVE',
    'FINISHED': 'FINISHED',
    'CANCELLED': 'CANCELLED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'SCHEDULED': 'SCHEDULED',
    'LIVE': 'LIVE',
    'FINISHED': 'FINISHED',
    'CANCELLED': 'CANCELLED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MatchStatus];
  @override
  final String wireName = 'MatchStatus';

  @override
  Object serialize(Serializers serializers, MatchStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MatchStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MatchStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
