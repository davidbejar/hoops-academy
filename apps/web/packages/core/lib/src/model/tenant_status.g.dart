// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TenantStatus _$ACTIVE = const TenantStatus._('ACTIVE');
const TenantStatus _$SUSPENDED = const TenantStatus._('SUSPENDED');
const TenantStatus _$WITHDRAWN = const TenantStatus._('WITHDRAWN');
const TenantStatus _$unknownDefaultOpenApi =
    const TenantStatus._('unknownDefaultOpenApi');

TenantStatus _$valueOf(String name) {
  switch (name) {
    case 'ACTIVE':
      return _$ACTIVE;
    case 'SUSPENDED':
      return _$SUSPENDED;
    case 'WITHDRAWN':
      return _$WITHDRAWN;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<TenantStatus> _$values =
    BuiltSet<TenantStatus>(const <TenantStatus>[
  _$ACTIVE,
  _$SUSPENDED,
  _$WITHDRAWN,
  _$unknownDefaultOpenApi,
]);

class _$TenantStatusMeta {
  const _$TenantStatusMeta();
  TenantStatus get ACTIVE => _$ACTIVE;
  TenantStatus get SUSPENDED => _$SUSPENDED;
  TenantStatus get WITHDRAWN => _$WITHDRAWN;
  TenantStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  TenantStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<TenantStatus> get values => _$values;
}

abstract class _$TenantStatusMixin {
  // ignore: non_constant_identifier_names
  _$TenantStatusMeta get TenantStatus => const _$TenantStatusMeta();
}

Serializer<TenantStatus> _$tenantStatusSerializer = _$TenantStatusSerializer();

class _$TenantStatusSerializer implements PrimitiveSerializer<TenantStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ACTIVE': 'ACTIVE',
    'SUSPENDED': 'SUSPENDED',
    'WITHDRAWN': 'WITHDRAWN',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ACTIVE': 'ACTIVE',
    'SUSPENDED': 'SUSPENDED',
    'WITHDRAWN': 'WITHDRAWN',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TenantStatus];
  @override
  final String wireName = 'TenantStatus';

  @override
  Object serialize(Serializers serializers, TenantStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TenantStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TenantStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
