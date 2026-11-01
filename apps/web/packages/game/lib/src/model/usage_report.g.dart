// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UsageReportServiceEnum _$usageReportServiceEnum_core =
    const UsageReportServiceEnum._('core');
const UsageReportServiceEnum _$usageReportServiceEnum_game =
    const UsageReportServiceEnum._('game');
const UsageReportServiceEnum _$usageReportServiceEnum_athlete =
    const UsageReportServiceEnum._('athlete');
const UsageReportServiceEnum _$usageReportServiceEnum_unknownDefaultOpenApi =
    const UsageReportServiceEnum._('unknownDefaultOpenApi');

UsageReportServiceEnum _$usageReportServiceEnumValueOf(String name) {
  switch (name) {
    case 'core':
      return _$usageReportServiceEnum_core;
    case 'game':
      return _$usageReportServiceEnum_game;
    case 'athlete':
      return _$usageReportServiceEnum_athlete;
    case 'unknownDefaultOpenApi':
      return _$usageReportServiceEnum_unknownDefaultOpenApi;
    default:
      return _$usageReportServiceEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UsageReportServiceEnum> _$usageReportServiceEnumValues =
    BuiltSet<UsageReportServiceEnum>(const <UsageReportServiceEnum>[
  _$usageReportServiceEnum_core,
  _$usageReportServiceEnum_game,
  _$usageReportServiceEnum_athlete,
  _$usageReportServiceEnum_unknownDefaultOpenApi,
]);

Serializer<UsageReportServiceEnum> _$usageReportServiceEnumSerializer =
    _$UsageReportServiceEnumSerializer();

class _$UsageReportServiceEnumSerializer
    implements PrimitiveSerializer<UsageReportServiceEnum> {
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
  final Iterable<Type> types = const <Type>[UsageReportServiceEnum];
  @override
  final String wireName = 'UsageReportServiceEnum';

  @override
  Object serialize(Serializers serializers, UsageReportServiceEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UsageReportServiceEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UsageReportServiceEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UsageReport extends UsageReport {
  @override
  final String tenantId;
  @override
  final UsageReportServiceEnum service;
  @override
  final DateTime collectedAt;
  @override
  final DateTime? lastActivityAt;
  @override
  final BuiltMap<String, int> counters;

  factory _$UsageReport([void Function(UsageReportBuilder)? updates]) =>
      (UsageReportBuilder()..update(updates))._build();

  _$UsageReport._(
      {required this.tenantId,
      required this.service,
      required this.collectedAt,
      this.lastActivityAt,
      required this.counters})
      : super._();
  @override
  UsageReport rebuild(void Function(UsageReportBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UsageReportBuilder toBuilder() => UsageReportBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UsageReport &&
        tenantId == other.tenantId &&
        service == other.service &&
        collectedAt == other.collectedAt &&
        lastActivityAt == other.lastActivityAt &&
        counters == other.counters;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, service.hashCode);
    _$hash = $jc(_$hash, collectedAt.hashCode);
    _$hash = $jc(_$hash, lastActivityAt.hashCode);
    _$hash = $jc(_$hash, counters.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UsageReport')
          ..add('tenantId', tenantId)
          ..add('service', service)
          ..add('collectedAt', collectedAt)
          ..add('lastActivityAt', lastActivityAt)
          ..add('counters', counters))
        .toString();
  }
}

class UsageReportBuilder implements Builder<UsageReport, UsageReportBuilder> {
  _$UsageReport? _$v;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  UsageReportServiceEnum? _service;
  UsageReportServiceEnum? get service => _$this._service;
  set service(UsageReportServiceEnum? service) => _$this._service = service;

  DateTime? _collectedAt;
  DateTime? get collectedAt => _$this._collectedAt;
  set collectedAt(DateTime? collectedAt) => _$this._collectedAt = collectedAt;

  DateTime? _lastActivityAt;
  DateTime? get lastActivityAt => _$this._lastActivityAt;
  set lastActivityAt(DateTime? lastActivityAt) =>
      _$this._lastActivityAt = lastActivityAt;

  MapBuilder<String, int>? _counters;
  MapBuilder<String, int> get counters =>
      _$this._counters ??= MapBuilder<String, int>();
  set counters(MapBuilder<String, int>? counters) =>
      _$this._counters = counters;

  UsageReportBuilder() {
    UsageReport._defaults(this);
  }

  UsageReportBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenantId = $v.tenantId;
      _service = $v.service;
      _collectedAt = $v.collectedAt;
      _lastActivityAt = $v.lastActivityAt;
      _counters = $v.counters.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UsageReport other) {
    _$v = other as _$UsageReport;
  }

  @override
  void update(void Function(UsageReportBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UsageReport build() => _build();

  _$UsageReport _build() {
    _$UsageReport _$result;
    try {
      _$result = _$v ??
          _$UsageReport._(
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'UsageReport', 'tenantId'),
            service: BuiltValueNullFieldError.checkNotNull(
                service, r'UsageReport', 'service'),
            collectedAt: BuiltValueNullFieldError.checkNotNull(
                collectedAt, r'UsageReport', 'collectedAt'),
            lastActivityAt: lastActivityAt,
            counters: counters.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'counters';
        counters.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UsageReport', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
