// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'band_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const BandStatus _$MATCHED = const BandStatus._('MATCHED');
const BandStatus _$NO_NORM = const BandStatus._('NO_NORM');
const BandStatus _$MISSING_PLAYER_DATA =
    const BandStatus._('MISSING_PLAYER_DATA');
const BandStatus _$unknownDefaultOpenApi =
    const BandStatus._('unknownDefaultOpenApi');

BandStatus _$valueOf(String name) {
  switch (name) {
    case 'MATCHED':
      return _$MATCHED;
    case 'NO_NORM':
      return _$NO_NORM;
    case 'MISSING_PLAYER_DATA':
      return _$MISSING_PLAYER_DATA;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<BandStatus> _$values = BuiltSet<BandStatus>(const <BandStatus>[
  _$MATCHED,
  _$NO_NORM,
  _$MISSING_PLAYER_DATA,
  _$unknownDefaultOpenApi,
]);

class _$BandStatusMeta {
  const _$BandStatusMeta();
  BandStatus get MATCHED => _$MATCHED;
  BandStatus get NO_NORM => _$NO_NORM;
  BandStatus get MISSING_PLAYER_DATA => _$MISSING_PLAYER_DATA;
  BandStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  BandStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<BandStatus> get values => _$values;
}

abstract class _$BandStatusMixin {
  // ignore: non_constant_identifier_names
  _$BandStatusMeta get BandStatus => const _$BandStatusMeta();
}

Serializer<BandStatus> _$bandStatusSerializer = _$BandStatusSerializer();

class _$BandStatusSerializer implements PrimitiveSerializer<BandStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MATCHED': 'MATCHED',
    'NO_NORM': 'NO_NORM',
    'MISSING_PLAYER_DATA': 'MISSING_PLAYER_DATA',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MATCHED': 'MATCHED',
    'NO_NORM': 'NO_NORM',
    'MISSING_PLAYER_DATA': 'MISSING_PLAYER_DATA',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[BandStatus];
  @override
  final String wireName = 'BandStatus';

  @override
  Object serialize(Serializers serializers, BandStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  BandStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      BandStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
