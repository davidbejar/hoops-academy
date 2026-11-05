// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditEvent extends AuditEvent {
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

  factory _$AuditEvent([void Function(AuditEventBuilder)? updates]) =>
      (AuditEventBuilder()..update(updates))._build();

  _$AuditEvent._(
      {required this.id,
      required this.at,
      required this.action,
      required this.actor,
      required this.target,
      required this.metadata})
      : super._();
  @override
  AuditEvent rebuild(void Function(AuditEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuditEventBuilder toBuilder() => AuditEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditEvent &&
        id == other.id &&
        at == other.at &&
        action == other.action &&
        actor == other.actor &&
        target == other.target &&
        metadata == other.metadata;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuditEvent')
          ..add('id', id)
          ..add('at', at)
          ..add('action', action)
          ..add('actor', actor)
          ..add('target', target)
          ..add('metadata', metadata))
        .toString();
  }
}

class AuditEventBuilder implements Builder<AuditEvent, AuditEventBuilder> {
  _$AuditEvent? _$v;

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

  AuditEventBuilder() {
    AuditEvent._defaults(this);
  }

  AuditEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _at = $v.at;
      _action = $v.action;
      _actor = $v.actor.toBuilder();
      _target = $v.target.toBuilder();
      _metadata = $v.metadata.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditEvent other) {
    _$v = other as _$AuditEvent;
  }

  @override
  void update(void Function(AuditEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditEvent build() => _build();

  _$AuditEvent _build() {
    _$AuditEvent _$result;
    try {
      _$result = _$v ??
          _$AuditEvent._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'AuditEvent', 'id'),
            at: BuiltValueNullFieldError.checkNotNull(at, r'AuditEvent', 'at'),
            action: BuiltValueNullFieldError.checkNotNull(
                action, r'AuditEvent', 'action'),
            actor: actor.build(),
            target: target.build(),
            metadata: metadata.build(),
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
            r'AuditEvent', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
