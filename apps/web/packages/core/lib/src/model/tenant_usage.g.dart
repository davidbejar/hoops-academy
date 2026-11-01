// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_usage.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TenantUsageUnavailableServicesEnum
    _$tenantUsageUnavailableServicesEnum_core =
    const TenantUsageUnavailableServicesEnum._('core');
const TenantUsageUnavailableServicesEnum
    _$tenantUsageUnavailableServicesEnum_game =
    const TenantUsageUnavailableServicesEnum._('game');
const TenantUsageUnavailableServicesEnum
    _$tenantUsageUnavailableServicesEnum_athlete =
    const TenantUsageUnavailableServicesEnum._('athlete');
const TenantUsageUnavailableServicesEnum
    _$tenantUsageUnavailableServicesEnum_unknownDefaultOpenApi =
    const TenantUsageUnavailableServicesEnum._('unknownDefaultOpenApi');

TenantUsageUnavailableServicesEnum _$tenantUsageUnavailableServicesEnumValueOf(
    String name) {
  switch (name) {
    case 'core':
      return _$tenantUsageUnavailableServicesEnum_core;
    case 'game':
      return _$tenantUsageUnavailableServicesEnum_game;
    case 'athlete':
      return _$tenantUsageUnavailableServicesEnum_athlete;
    case 'unknownDefaultOpenApi':
      return _$tenantUsageUnavailableServicesEnum_unknownDefaultOpenApi;
    default:
      return _$tenantUsageUnavailableServicesEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<TenantUsageUnavailableServicesEnum>
    _$tenantUsageUnavailableServicesEnumValues = BuiltSet<
        TenantUsageUnavailableServicesEnum>(const <TenantUsageUnavailableServicesEnum>[
  _$tenantUsageUnavailableServicesEnum_core,
  _$tenantUsageUnavailableServicesEnum_game,
  _$tenantUsageUnavailableServicesEnum_athlete,
  _$tenantUsageUnavailableServicesEnum_unknownDefaultOpenApi,
]);

Serializer<TenantUsageUnavailableServicesEnum>
    _$tenantUsageUnavailableServicesEnumSerializer =
    _$TenantUsageUnavailableServicesEnumSerializer();

class _$TenantUsageUnavailableServicesEnumSerializer
    implements PrimitiveSerializer<TenantUsageUnavailableServicesEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'core': 'core',
    'game': 'game',
    'athlete': 'athlete',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'core': 'core',
    'game': 'game',
    'athlete': 'athlete',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[TenantUsageUnavailableServicesEnum];
  @override
  final String wireName = 'TenantUsageUnavailableServicesEnum';

  @override
  Object serialize(
          Serializers serializers, TenantUsageUnavailableServicesEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TenantUsageUnavailableServicesEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TenantUsageUnavailableServicesEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TenantUsage extends TenantUsage {
  @override
  final String tenantId;
  @override
  final DateTime collectedAt;
  @override
  final BuiltList<UsageReport> services;
  @override
  final BuiltList<TenantUsageUnavailableServicesEnum> unavailableServices;

  factory _$TenantUsage([void Function(TenantUsageBuilder)? updates]) =>
      (TenantUsageBuilder()..update(updates))._build();

  _$TenantUsage._(
      {required this.tenantId,
      required this.collectedAt,
      required this.services,
      required this.unavailableServices})
      : super._();
  @override
  TenantUsage rebuild(void Function(TenantUsageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantUsageBuilder toBuilder() => TenantUsageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantUsage &&
        tenantId == other.tenantId &&
        collectedAt == other.collectedAt &&
        services == other.services &&
        unavailableServices == other.unavailableServices;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, collectedAt.hashCode);
    _$hash = $jc(_$hash, services.hashCode);
    _$hash = $jc(_$hash, unavailableServices.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantUsage')
          ..add('tenantId', tenantId)
          ..add('collectedAt', collectedAt)
          ..add('services', services)
          ..add('unavailableServices', unavailableServices))
        .toString();
  }
}

class TenantUsageBuilder implements Builder<TenantUsage, TenantUsageBuilder> {
  _$TenantUsage? _$v;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  DateTime? _collectedAt;
  DateTime? get collectedAt => _$this._collectedAt;
  set collectedAt(DateTime? collectedAt) => _$this._collectedAt = collectedAt;

  ListBuilder<UsageReport>? _services;
  ListBuilder<UsageReport> get services =>
      _$this._services ??= ListBuilder<UsageReport>();
  set services(ListBuilder<UsageReport>? services) =>
      _$this._services = services;

  ListBuilder<TenantUsageUnavailableServicesEnum>? _unavailableServices;
  ListBuilder<TenantUsageUnavailableServicesEnum> get unavailableServices =>
      _$this._unavailableServices ??=
          ListBuilder<TenantUsageUnavailableServicesEnum>();
  set unavailableServices(
          ListBuilder<TenantUsageUnavailableServicesEnum>?
              unavailableServices) =>
      _$this._unavailableServices = unavailableServices;

  TenantUsageBuilder() {
    TenantUsage._defaults(this);
  }

  TenantUsageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenantId = $v.tenantId;
      _collectedAt = $v.collectedAt;
      _services = $v.services.toBuilder();
      _unavailableServices = $v.unavailableServices.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantUsage other) {
    _$v = other as _$TenantUsage;
  }

  @override
  void update(void Function(TenantUsageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantUsage build() => _build();

  _$TenantUsage _build() {
    _$TenantUsage _$result;
    try {
      _$result = _$v ??
          _$TenantUsage._(
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'TenantUsage', 'tenantId'),
            collectedAt: BuiltValueNullFieldError.checkNotNull(
                collectedAt, r'TenantUsage', 'collectedAt'),
            services: services.build(),
            unavailableServices: unavailableServices.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'services';
        services.build();
        _$failedField = 'unavailableServices';
        unavailableServices.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TenantUsage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
