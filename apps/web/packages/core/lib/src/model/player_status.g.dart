// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PlayerStatus _$PENDING_APPROVAL =
    const PlayerStatus._('PENDING_APPROVAL');
const PlayerStatus _$ACTIVE = const PlayerStatus._('ACTIVE');
const PlayerStatus _$ORPHAN = const PlayerStatus._('ORPHAN');
const PlayerStatus _$WITHDRAWN = const PlayerStatus._('WITHDRAWN');
const PlayerStatus _$unknownDefaultOpenApi =
    const PlayerStatus._('unknownDefaultOpenApi');

PlayerStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING_APPROVAL':
      return _$PENDING_APPROVAL;
    case 'ACTIVE':
      return _$ACTIVE;
    case 'ORPHAN':
      return _$ORPHAN;
    case 'WITHDRAWN':
      return _$WITHDRAWN;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<PlayerStatus> _$values =
    BuiltSet<PlayerStatus>(const <PlayerStatus>[
  _$PENDING_APPROVAL,
  _$ACTIVE,
  _$ORPHAN,
  _$WITHDRAWN,
  _$unknownDefaultOpenApi,
]);

class _$PlayerStatusMeta {
  const _$PlayerStatusMeta();
  PlayerStatus get PENDING_APPROVAL => _$PENDING_APPROVAL;
  PlayerStatus get ACTIVE => _$ACTIVE;
  PlayerStatus get ORPHAN => _$ORPHAN;
  PlayerStatus get WITHDRAWN => _$WITHDRAWN;
  PlayerStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  PlayerStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<PlayerStatus> get values => _$values;
}

abstract class _$PlayerStatusMixin {
  // ignore: non_constant_identifier_names
  _$PlayerStatusMeta get PlayerStatus => const _$PlayerStatusMeta();
}

Serializer<PlayerStatus> _$playerStatusSerializer = _$PlayerStatusSerializer();

class _$PlayerStatusSerializer implements PrimitiveSerializer<PlayerStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING_APPROVAL': 'PENDING_APPROVAL',
    'ACTIVE': 'ACTIVE',
    'ORPHAN': 'ORPHAN',
    'WITHDRAWN': 'WITHDRAWN',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING_APPROVAL': 'PENDING_APPROVAL',
    'ACTIVE': 'ACTIVE',
    'ORPHAN': 'ORPHAN',
    'WITHDRAWN': 'WITHDRAWN',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[PlayerStatus];
  @override
  final String wireName = 'PlayerStatus';

  @override
  Object serialize(Serializers serializers, PlayerStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PlayerStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PlayerStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
