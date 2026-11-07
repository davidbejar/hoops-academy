// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_backfill_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EventBackfillRequest extends EventBackfillRequest {
  @override
  final String? tenantId;
  @override
  final bool? force;

  factory _$EventBackfillRequest(
          [void Function(EventBackfillRequestBuilder)? updates]) =>
      (EventBackfillRequestBuilder()..update(updates))._build();

  _$EventBackfillRequest._({this.tenantId, this.force}) : super._();
  @override
  EventBackfillRequest rebuild(
          void Function(EventBackfillRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EventBackfillRequestBuilder toBuilder() =>
      EventBackfillRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EventBackfillRequest &&
        tenantId == other.tenantId &&
        force == other.force;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, force.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EventBackfillRequest')
          ..add('tenantId', tenantId)
          ..add('force', force))
        .toString();
  }
}

class EventBackfillRequestBuilder
    implements Builder<EventBackfillRequest, EventBackfillRequestBuilder> {
  _$EventBackfillRequest? _$v;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  bool? _force;
  bool? get force => _$this._force;
  set force(bool? force) => _$this._force = force;

  EventBackfillRequestBuilder() {
    EventBackfillRequest._defaults(this);
  }

  EventBackfillRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tenantId = $v.tenantId;
      _force = $v.force;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EventBackfillRequest other) {
    _$v = other as _$EventBackfillRequest;
  }

  @override
  void update(void Function(EventBackfillRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EventBackfillRequest build() => _build();

  _$EventBackfillRequest _build() {
    final _$result = _$v ??
        _$EventBackfillRequest._(
          tenantId: tenantId,
          force: force,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
