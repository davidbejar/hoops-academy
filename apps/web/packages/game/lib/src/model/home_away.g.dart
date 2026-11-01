// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_away.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const HomeAway _$HOME = const HomeAway._('HOME');
const HomeAway _$AWAY = const HomeAway._('AWAY');
const HomeAway _$unknownDefaultOpenApi =
    const HomeAway._('unknownDefaultOpenApi');

HomeAway _$valueOf(String name) {
  switch (name) {
    case 'HOME':
      return _$HOME;
    case 'AWAY':
      return _$AWAY;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<HomeAway> _$values = BuiltSet<HomeAway>(const <HomeAway>[
  _$HOME,
  _$AWAY,
  _$unknownDefaultOpenApi,
]);

class _$HomeAwayMeta {
  const _$HomeAwayMeta();
  HomeAway get HOME => _$HOME;
  HomeAway get AWAY => _$AWAY;
  HomeAway get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  HomeAway valueOf(String name) => _$valueOf(name);
  BuiltSet<HomeAway> get values => _$values;
}

abstract class _$HomeAwayMixin {
  // ignore: non_constant_identifier_names
  _$HomeAwayMeta get HomeAway => const _$HomeAwayMeta();
}

Serializer<HomeAway> _$homeAwaySerializer = _$HomeAwaySerializer();

class _$HomeAwaySerializer implements PrimitiveSerializer<HomeAway> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'HOME': 'HOME',
    'AWAY': 'AWAY',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'HOME': 'HOME',
    'AWAY': 'AWAY',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[HomeAway];
  @override
  final String wireName = 'HomeAway';

  @override
  Object serialize(Serializers serializers, HomeAway object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  HomeAway deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      HomeAway.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
