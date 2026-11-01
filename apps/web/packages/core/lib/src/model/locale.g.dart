// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Locale _$es = const Locale._('es');
const Locale _$en = const Locale._('en');
const Locale _$id = const Locale._('id');
const Locale _$unknownDefaultOpenApi = const Locale._('unknownDefaultOpenApi');

Locale _$valueOf(String name) {
  switch (name) {
    case 'es':
      return _$es;
    case 'en':
      return _$en;
    case 'id':
      return _$id;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<Locale> _$values = BuiltSet<Locale>(const <Locale>[
  _$es,
  _$en,
  _$id,
  _$unknownDefaultOpenApi,
]);

class _$LocaleMeta {
  const _$LocaleMeta();
  Locale get es => _$es;
  Locale get en => _$en;
  Locale get id => _$id;
  Locale get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  Locale valueOf(String name) => _$valueOf(name);
  BuiltSet<Locale> get values => _$values;
}

abstract class _$LocaleMixin {
  // ignore: non_constant_identifier_names
  _$LocaleMeta get Locale => const _$LocaleMeta();
}

Serializer<Locale> _$localeSerializer = _$LocaleSerializer();

class _$LocaleSerializer implements PrimitiveSerializer<Locale> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'es': 'es',
    'en': 'en',
    'id': 'id',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'es': 'es',
    'en': 'en',
    'id': 'id',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[Locale];
  @override
  final String wireName = 'Locale';

  @override
  Object serialize(Serializers serializers, Locale object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  Locale deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      Locale.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
