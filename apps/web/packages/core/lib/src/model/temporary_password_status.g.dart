// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temporary_password_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TemporaryPasswordStatus _$ACTIVE =
    const TemporaryPasswordStatus._('ACTIVE');
const TemporaryPasswordStatus _$EXPIRED =
    const TemporaryPasswordStatus._('EXPIRED');
const TemporaryPasswordStatus _$NONE = const TemporaryPasswordStatus._('NONE');
const TemporaryPasswordStatus _$unknownDefaultOpenApi =
    const TemporaryPasswordStatus._('unknownDefaultOpenApi');

TemporaryPasswordStatus _$valueOf(String name) {
  switch (name) {
    case 'ACTIVE':
      return _$ACTIVE;
    case 'EXPIRED':
      return _$EXPIRED;
    case 'NONE':
      return _$NONE;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<TemporaryPasswordStatus> _$values =
    BuiltSet<TemporaryPasswordStatus>(const <TemporaryPasswordStatus>[
  _$ACTIVE,
  _$EXPIRED,
  _$NONE,
  _$unknownDefaultOpenApi,
]);

class _$TemporaryPasswordStatusMeta {
  const _$TemporaryPasswordStatusMeta();
  TemporaryPasswordStatus get ACTIVE => _$ACTIVE;
  TemporaryPasswordStatus get EXPIRED => _$EXPIRED;
  TemporaryPasswordStatus get NONE => _$NONE;
  TemporaryPasswordStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  TemporaryPasswordStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<TemporaryPasswordStatus> get values => _$values;
}

abstract class _$TemporaryPasswordStatusMixin {
  // ignore: non_constant_identifier_names
  _$TemporaryPasswordStatusMeta get TemporaryPasswordStatus =>
      const _$TemporaryPasswordStatusMeta();
}

Serializer<TemporaryPasswordStatus> _$temporaryPasswordStatusSerializer =
    _$TemporaryPasswordStatusSerializer();

class _$TemporaryPasswordStatusSerializer
    implements PrimitiveSerializer<TemporaryPasswordStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ACTIVE': 'ACTIVE',
    'EXPIRED': 'EXPIRED',
    'NONE': 'NONE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ACTIVE': 'ACTIVE',
    'EXPIRED': 'EXPIRED',
    'NONE': 'NONE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TemporaryPasswordStatus];
  @override
  final String wireName = 'TemporaryPasswordStatus';

  @override
  Object serialize(Serializers serializers, TemporaryPasswordStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TemporaryPasswordStatus deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TemporaryPasswordStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
