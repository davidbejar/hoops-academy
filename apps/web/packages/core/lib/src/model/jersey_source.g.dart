// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jersey_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const JerseySource _$REQUESTED = const JerseySource._('REQUESTED');
const JerseySource _$PREFERRED = const JerseySource._('PREFERRED');
const JerseySource _$PREVIOUS = const JerseySource._('PREVIOUS');
const JerseySource _$NONE = const JerseySource._('NONE');
const JerseySource _$unknownDefaultOpenApi =
    const JerseySource._('unknownDefaultOpenApi');

JerseySource _$valueOf(String name) {
  switch (name) {
    case 'REQUESTED':
      return _$REQUESTED;
    case 'PREFERRED':
      return _$PREFERRED;
    case 'PREVIOUS':
      return _$PREVIOUS;
    case 'NONE':
      return _$NONE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<JerseySource> _$values =
    BuiltSet<JerseySource>(const <JerseySource>[
  _$REQUESTED,
  _$PREFERRED,
  _$PREVIOUS,
  _$NONE,
  _$unknownDefaultOpenApi,
]);

class _$JerseySourceMeta {
  const _$JerseySourceMeta();
  JerseySource get REQUESTED => _$REQUESTED;
  JerseySource get PREFERRED => _$PREFERRED;
  JerseySource get PREVIOUS => _$PREVIOUS;
  JerseySource get NONE => _$NONE;
  JerseySource get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  JerseySource valueOf(String name) => _$valueOf(name);
  BuiltSet<JerseySource> get values => _$values;
}

abstract class _$JerseySourceMixin {
  // ignore: non_constant_identifier_names
  _$JerseySourceMeta get JerseySource => const _$JerseySourceMeta();
}

Serializer<JerseySource> _$jerseySourceSerializer = _$JerseySourceSerializer();

class _$JerseySourceSerializer implements PrimitiveSerializer<JerseySource> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'REQUESTED': 'REQUESTED',
    'PREFERRED': 'PREFERRED',
    'PREVIOUS': 'PREVIOUS',
    'NONE': 'NONE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'REQUESTED': 'REQUESTED',
    'PREFERRED': 'PREFERRED',
    'PREVIOUS': 'PREVIOUS',
    'NONE': 'NONE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[JerseySource];
  @override
  final String wireName = 'JerseySource';

  @override
  Object serialize(Serializers serializers, JerseySource object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  JerseySource deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      JerseySource.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
