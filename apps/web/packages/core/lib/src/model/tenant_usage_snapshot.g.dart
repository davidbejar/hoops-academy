// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_usage_snapshot.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TenantUsageSnapshotUnavailableServicesEnum
    _$tenantUsageSnapshotUnavailableServicesEnum_core =
    const TenantUsageSnapshotUnavailableServicesEnum._('core');
const TenantUsageSnapshotUnavailableServicesEnum
    _$tenantUsageSnapshotUnavailableServicesEnum_game =
    const TenantUsageSnapshotUnavailableServicesEnum._('game');
const TenantUsageSnapshotUnavailableServicesEnum
    _$tenantUsageSnapshotUnavailableServicesEnum_athlete =
    const TenantUsageSnapshotUnavailableServicesEnum._('athlete');
const TenantUsageSnapshotUnavailableServicesEnum
    _$tenantUsageSnapshotUnavailableServicesEnum_unknownDefaultOpenApi =
    const TenantUsageSnapshotUnavailableServicesEnum._('unknownDefaultOpenApi');

TenantUsageSnapshotUnavailableServicesEnum
    _$tenantUsageSnapshotUnavailableServicesEnumValueOf(String name) {
  switch (name) {
    case 'core':
      return _$tenantUsageSnapshotUnavailableServicesEnum_core;
    case 'game':
      return _$tenantUsageSnapshotUnavailableServicesEnum_game;
    case 'athlete':
      return _$tenantUsageSnapshotUnavailableServicesEnum_athlete;
    case 'unknownDefaultOpenApi':
      return _$tenantUsageSnapshotUnavailableServicesEnum_unknownDefaultOpenApi;
    default:
      return _$tenantUsageSnapshotUnavailableServicesEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<TenantUsageSnapshotUnavailableServicesEnum>
    _$tenantUsageSnapshotUnavailableServicesEnumValues = BuiltSet<
        TenantUsageSnapshotUnavailableServicesEnum>(const <TenantUsageSnapshotUnavailableServicesEnum>[
  _$tenantUsageSnapshotUnavailableServicesEnum_core,
  _$tenantUsageSnapshotUnavailableServicesEnum_game,
  _$tenantUsageSnapshotUnavailableServicesEnum_athlete,
  _$tenantUsageSnapshotUnavailableServicesEnum_unknownDefaultOpenApi,
]);

Serializer<TenantUsageSnapshotUnavailableServicesEnum>
    _$tenantUsageSnapshotUnavailableServicesEnumSerializer =
    _$TenantUsageSnapshotUnavailableServicesEnumSerializer();

class _$TenantUsageSnapshotUnavailableServicesEnumSerializer
    implements PrimitiveSerializer<TenantUsageSnapshotUnavailableServicesEnum> {
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
  final Iterable<Type> types = const <Type>[
    TenantUsageSnapshotUnavailableServicesEnum
  ];
  @override
  final String wireName = 'TenantUsageSnapshotUnavailableServicesEnum';

  @override
  Object serialize(Serializers serializers,
          TenantUsageSnapshotUnavailableServicesEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  TenantUsageSnapshotUnavailableServicesEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      TenantUsageSnapshotUnavailableServicesEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$TenantUsageSnapshot extends TenantUsageSnapshot {
  @override
  final Date date;
  @override
  final DateTime collectedAt;
  @override
  final BuiltList<UsageReport> services;
  @override
  final BuiltList<TenantUsageSnapshotUnavailableServicesEnum>
      unavailableServices;

  factory _$TenantUsageSnapshot(
          [void Function(TenantUsageSnapshotBuilder)? updates]) =>
      (TenantUsageSnapshotBuilder()..update(updates))._build();

  _$TenantUsageSnapshot._(
      {required this.date,
      required this.collectedAt,
      required this.services,
      required this.unavailableServices})
      : super._();
  @override
  TenantUsageSnapshot rebuild(
          void Function(TenantUsageSnapshotBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantUsageSnapshotBuilder toBuilder() =>
      TenantUsageSnapshotBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantUsageSnapshot &&
        date == other.date &&
        collectedAt == other.collectedAt &&
        services == other.services &&
        unavailableServices == other.unavailableServices;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jc(_$hash, collectedAt.hashCode);
    _$hash = $jc(_$hash, services.hashCode);
    _$hash = $jc(_$hash, unavailableServices.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantUsageSnapshot')
          ..add('date', date)
          ..add('collectedAt', collectedAt)
          ..add('services', services)
          ..add('unavailableServices', unavailableServices))
        .toString();
  }
}

class TenantUsageSnapshotBuilder
    implements Builder<TenantUsageSnapshot, TenantUsageSnapshotBuilder> {
  _$TenantUsageSnapshot? _$v;

  Date? _date;
  Date? get date => _$this._date;
  set date(Date? date) => _$this._date = date;

  DateTime? _collectedAt;
  DateTime? get collectedAt => _$this._collectedAt;
  set collectedAt(DateTime? collectedAt) => _$this._collectedAt = collectedAt;

  ListBuilder<UsageReport>? _services;
  ListBuilder<UsageReport> get services =>
      _$this._services ??= ListBuilder<UsageReport>();
  set services(ListBuilder<UsageReport>? services) =>
      _$this._services = services;

  ListBuilder<TenantUsageSnapshotUnavailableServicesEnum>? _unavailableServices;
  ListBuilder<TenantUsageSnapshotUnavailableServicesEnum>
      get unavailableServices => _$this._unavailableServices ??=
          ListBuilder<TenantUsageSnapshotUnavailableServicesEnum>();
  set unavailableServices(
          ListBuilder<TenantUsageSnapshotUnavailableServicesEnum>?
              unavailableServices) =>
      _$this._unavailableServices = unavailableServices;

  TenantUsageSnapshotBuilder() {
    TenantUsageSnapshot._defaults(this);
  }

  TenantUsageSnapshotBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _date = $v.date;
      _collectedAt = $v.collectedAt;
      _services = $v.services.toBuilder();
      _unavailableServices = $v.unavailableServices.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantUsageSnapshot other) {
    _$v = other as _$TenantUsageSnapshot;
  }

  @override
  void update(void Function(TenantUsageSnapshotBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantUsageSnapshot build() => _build();

  _$TenantUsageSnapshot _build() {
    _$TenantUsageSnapshot _$result;
    try {
      _$result = _$v ??
          _$TenantUsageSnapshot._(
            date: BuiltValueNullFieldError.checkNotNull(
                date, r'TenantUsageSnapshot', 'date'),
            collectedAt: BuiltValueNullFieldError.checkNotNull(
                collectedAt, r'TenantUsageSnapshot', 'collectedAt'),
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
            r'TenantUsageSnapshot', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
