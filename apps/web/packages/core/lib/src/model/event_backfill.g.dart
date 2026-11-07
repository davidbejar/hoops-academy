// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_backfill.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EventBackfill extends EventBackfill {
  @override
  final bool force;
  @override
  final int tenants;
  @override
  final int failed;
  @override
  final int appended;
  @override
  final BuiltMap<String, int> appendedByTopic;

  factory _$EventBackfill([void Function(EventBackfillBuilder)? updates]) =>
      (EventBackfillBuilder()..update(updates))._build();

  _$EventBackfill._(
      {required this.force,
      required this.tenants,
      required this.failed,
      required this.appended,
      required this.appendedByTopic})
      : super._();
  @override
  EventBackfill rebuild(void Function(EventBackfillBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EventBackfillBuilder toBuilder() => EventBackfillBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EventBackfill &&
        force == other.force &&
        tenants == other.tenants &&
        failed == other.failed &&
        appended == other.appended &&
        appendedByTopic == other.appendedByTopic;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, force.hashCode);
    _$hash = $jc(_$hash, tenants.hashCode);
    _$hash = $jc(_$hash, failed.hashCode);
    _$hash = $jc(_$hash, appended.hashCode);
    _$hash = $jc(_$hash, appendedByTopic.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EventBackfill')
          ..add('force', force)
          ..add('tenants', tenants)
          ..add('failed', failed)
          ..add('appended', appended)
          ..add('appendedByTopic', appendedByTopic))
        .toString();
  }
}

class EventBackfillBuilder
    implements Builder<EventBackfill, EventBackfillBuilder> {
  _$EventBackfill? _$v;

  bool? _force;
  bool? get force => _$this._force;
  set force(bool? force) => _$this._force = force;

  int? _tenants;
  int? get tenants => _$this._tenants;
  set tenants(int? tenants) => _$this._tenants = tenants;

  int? _failed;
  int? get failed => _$this._failed;
  set failed(int? failed) => _$this._failed = failed;

  int? _appended;
  int? get appended => _$this._appended;
  set appended(int? appended) => _$this._appended = appended;

  MapBuilder<String, int>? _appendedByTopic;
  MapBuilder<String, int> get appendedByTopic =>
      _$this._appendedByTopic ??= MapBuilder<String, int>();
  set appendedByTopic(MapBuilder<String, int>? appendedByTopic) =>
      _$this._appendedByTopic = appendedByTopic;

  EventBackfillBuilder() {
    EventBackfill._defaults(this);
  }

  EventBackfillBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _force = $v.force;
      _tenants = $v.tenants;
      _failed = $v.failed;
      _appended = $v.appended;
      _appendedByTopic = $v.appendedByTopic.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EventBackfill other) {
    _$v = other as _$EventBackfill;
  }

  @override
  void update(void Function(EventBackfillBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EventBackfill build() => _build();

  _$EventBackfill _build() {
    _$EventBackfill _$result;
    try {
      _$result = _$v ??
          _$EventBackfill._(
            force: BuiltValueNullFieldError.checkNotNull(
                force, r'EventBackfill', 'force'),
            tenants: BuiltValueNullFieldError.checkNotNull(
                tenants, r'EventBackfill', 'tenants'),
            failed: BuiltValueNullFieldError.checkNotNull(
                failed, r'EventBackfill', 'failed'),
            appended: BuiltValueNullFieldError.checkNotNull(
                appended, r'EventBackfill', 'appended'),
            appendedByTopic: appendedByTopic.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'appendedByTopic';
        appendedByTopic.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EventBackfill', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
