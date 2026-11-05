// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_audit_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlatformAuditEvent extends PlatformAuditEvent {
  @override
  final String id;
  @override
  final DateTime at;
  @override
  final AuditAction action;
  @override
  final AuditActor actor;
  @override
  final AuditTarget target;
  @override
  final BuiltMap<String, JsonObject?> metadata;
  @override
  final String tenantId;
  @override
  final String tenantName;

  factory _$PlatformAuditEvent(
          [void Function(PlatformAuditEventBuilder)? updates]) =>
      (PlatformAuditEventBuilder()..update(updates))._build();

  _$PlatformAuditEvent._(
      {required this.id,
      required this.at,
      required this.action,
      required this.actor,
      required this.target,
      required this.metadata,
      required this.tenantId,
      required this.tenantName})
      : super._();
  @override
  PlatformAuditEvent rebuild(
          void Function(PlatformAuditEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlatformAuditEventBuilder toBuilder() =>
      PlatformAuditEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlatformAuditEvent &&
        id == other.id &&
        at == other.at &&
        action == other.action &&
        actor == other.actor &&
        target == other.target &&
        metadata == other.metadata &&
        tenantId == other.tenantId &&
        tenantName == other.tenantName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, at.hashCode);
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, actor.hashCode);
    _$hash = $jc(_$hash, target.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, tenantName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlatformAuditEvent')
          ..add('id', id)
          ..add('at', at)
          ..add('action', action)
          ..add('actor', actor)
          ..add('target', target)
          ..add('metadata', metadata)
          ..add('tenantId', tenantId)
          ..add('tenantName', tenantName))
        .toString();
  }
}

class PlatformAuditEventBuilder
    implements Builder<PlatformAuditEvent, PlatformAuditEventBuilder> {
  _$PlatformAuditEvent? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _at;
  DateTime? get at => _$this._at;
  set at(DateTime? at) => _$this._at = at;

  AuditAction? _action;
  AuditAction? get action => _$this._action;
  set action(AuditAction? action) => _$this._action = action;

  AuditActorBuilder? _actor;
  AuditActorBuilder get actor => _$this._actor ??= AuditActorBuilder();
  set actor(AuditActorBuilder? actor) => _$this._actor = actor;

  AuditTargetBuilder? _target;
  AuditTargetBuilder get target => _$this._target ??= AuditTargetBuilder();
  set target(AuditTargetBuilder? target) => _$this._target = target;

  MapBuilder<String, JsonObject?>? _metadata;
  MapBuilder<String, JsonObject?> get metadata =>
      _$this._metadata ??= MapBuilder<String, JsonObject?>();
  set metadata(MapBuilder<String, JsonObject?>? metadata) =>
      _$this._metadata = metadata;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  String? _tenantName;
  String? get tenantName => _$this._tenantName;
  set tenantName(String? tenantName) => _$this._tenantName = tenantName;

  PlatformAuditEventBuilder() {
    PlatformAuditEvent._defaults(this);
  }

  PlatformAuditEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _at = $v.at;
      _action = $v.action;
      _actor = $v.actor.toBuilder();
      _target = $v.target.toBuilder();
      _metadata = $v.metadata.toBuilder();
      _tenantId = $v.tenantId;
      _tenantName = $v.tenantName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlatformAuditEvent other) {
    _$v = other as _$PlatformAuditEvent;
  }

  @override
  void update(void Function(PlatformAuditEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlatformAuditEvent build() => _build();

  _$PlatformAuditEvent _build() {
    _$PlatformAuditEvent _$result;
    try {
      _$result = _$v ??
          _$PlatformAuditEvent._(
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PlatformAuditEvent', 'id'),
            at: BuiltValueNullFieldError.checkNotNull(
                at, r'PlatformAuditEvent', 'at'),
            action: BuiltValueNullFieldError.checkNotNull(
                action, r'PlatformAuditEvent', 'action'),
            actor: actor.build(),
            target: target.build(),
            metadata: metadata.build(),
            tenantId: BuiltValueNullFieldError.checkNotNull(
                tenantId, r'PlatformAuditEvent', 'tenantId'),
            tenantName: BuiltValueNullFieldError.checkNotNull(
                tenantName, r'PlatformAuditEvent', 'tenantName'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'actor';
        actor.build();
        _$failedField = 'target';
        target.build();
        _$failedField = 'metadata';
        metadata.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlatformAuditEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
