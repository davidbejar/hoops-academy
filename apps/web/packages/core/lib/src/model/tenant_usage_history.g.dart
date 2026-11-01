// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_usage_history.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantUsageHistory extends TenantUsageHistory {
  @override
  final String tenantId;
  @override
  final Date from;
  @override
  final Date to;
  @override
  final BuiltList<TenantUsageSnapshot> snapshots;

  factory _$TenantUsageHistory(
          [void Function(TenantUsageHistoryBuilder)? updates]) =>
      (TenantUsageHistoryBuilder()..update(updates))._build();

  _$TenantUsageHistory._(
      {required this.tenantId,
      required this.from,
      required this.to,
      required this.snapshots})
      : super._();
  @override
  TenantUsageHistory rebuild(
          void Function(TenantUsageHistoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantUsageHistoryBuilder toBuilder() =>
      TenantUsageHistoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantUsageHistory &&
        tenantId == other.tenantId &&
        from == other.from &&
        to == other.to &&
        snapshots == other.snapshots;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, from.hashCode);
    _$hash = $jc(_$hash, to.hashCode);
    _$hash = $jc(_$hash, snapshots.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantUsageHistory')
          ..add('tenantId', tenantId)
          ..add('from', from)
          ..add('to', to)
          ..add('snapshots', snapshots))
        .toString();
  }
}

class TenantUsageHistoryBuilder
    implements Builder<TenantUsageHistory, TenantUsageHistoryBuilder> {
  _$TenantUsageHistory? _$v;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  Date? _from;
  Date? get from => _$this._from;
  set from(Date? from) => _$this._from = from;

  Date? _to;
  Date? get to => _$this._to;
  set to(Date? to) => _$this._to = to;

  ListBuilder<TenantUsageSnapshot>? _snapshots;
  ListBuilder<TenantUsageSnapshot> get snapshots =>
      _$this._snapshots ??= ListBuilder<TenantUsageSnapshot>();
  set snapshots(ListBuilder<TenantUsageSnapshot>? snapshots) =>
      _$this._snapshots = snapshots;

  TenantUsageHistoryBuilder() {
    TenantUsageHistory._defaults(this);
  }

  TenantUsageHistoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenantId = $v.tenantId;
      _from = $v.from;
      _to = $v.to;
      _snapshots = $v.snapshots.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantUsageHistory other) {
    _$v = other as _$TenantUsageHistory;
  }

  @override
  void update(void Function(TenantUsageHistoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantUsageHistory build() => _build();

  _$TenantUsageHistory _build() {
    _$TenantUsageHistory _$result;
    try {
      _$result = _$v ??
          _$TenantUsageHistory._(
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'TenantUsageHistory', 'tenantId'),
            from: BuiltValueNullFieldError.checkNotNull(
                from, r'TenantUsageHistory', 'from'),
            to: BuiltValueNullFieldError.checkNotNull(
                to, r'TenantUsageHistory', 'to'),
            snapshots: snapshots.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'snapshots';
        snapshots.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TenantUsageHistory', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
