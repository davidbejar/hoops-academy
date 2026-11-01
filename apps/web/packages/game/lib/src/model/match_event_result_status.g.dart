// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_event_result_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MatchEventResultStatus _$ACCEPTED =
    const MatchEventResultStatus._('ACCEPTED');
const MatchEventResultStatus _$DUPLICATE =
    const MatchEventResultStatus._('DUPLICATE');
const MatchEventResultStatus _$REJECTED =
    const MatchEventResultStatus._('REJECTED');
const MatchEventResultStatus _$unknownDefaultOpenApi =
    const MatchEventResultStatus._('unknownDefaultOpenApi');

MatchEventResultStatus _$valueOf(String name) {
  switch (name) {
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'DUPLICATE':
      return _$DUPLICATE;
    case 'REJECTED':
      return _$REJECTED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<MatchEventResultStatus> _$values =
    BuiltSet<MatchEventResultStatus>(const <MatchEventResultStatus>[
  _$ACCEPTED,
  _$DUPLICATE,
  _$REJECTED,
  _$unknownDefaultOpenApi,
]);

class _$MatchEventResultStatusMeta {
  const _$MatchEventResultStatusMeta();
  MatchEventResultStatus get ACCEPTED => _$ACCEPTED;
  MatchEventResultStatus get DUPLICATE => _$DUPLICATE;
  MatchEventResultStatus get REJECTED => _$REJECTED;
  MatchEventResultStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  MatchEventResultStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<MatchEventResultStatus> get values => _$values;
}

abstract class _$MatchEventResultStatusMixin {
  // ignore: non_constant_identifier_names
  _$MatchEventResultStatusMeta get MatchEventResultStatus =>
      const _$MatchEventResultStatusMeta();
}

Serializer<MatchEventResultStatus> _$matchEventResultStatusSerializer =
    _$MatchEventResultStatusSerializer();

class _$MatchEventResultStatusSerializer
    implements PrimitiveSerializer<MatchEventResultStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ACCEPTED': 'ACCEPTED',
    'DUPLICATE': 'DUPLICATE',
    'REJECTED': 'REJECTED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ACCEPTED': 'ACCEPTED',
    'DUPLICATE': 'DUPLICATE',
    'REJECTED': 'REJECTED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MatchEventResultStatus];
  @override
  final String wireName = 'MatchEventResultStatus';

  @override
  Object serialize(Serializers serializers, MatchEventResultStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MatchEventResultStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MatchEventResultStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
