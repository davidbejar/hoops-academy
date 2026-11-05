// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_actor.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditActor extends AuditActor {
  @override
  final AuditActorKind kind;
  @override
  final String subject;
  @override
  final String? personId;
  @override
  final String? displayName;

  factory _$AuditActor([void Function(AuditActorBuilder)? updates]) =>
      (AuditActorBuilder()..update(updates))._build();

  _$AuditActor._(
      {required this.kind,
      required this.subject,
      this.personId,
      this.displayName})
      : super._();
  @override
  AuditActor rebuild(void Function(AuditActorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuditActorBuilder toBuilder() => AuditActorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditActor &&
        kind == other.kind &&
        subject == other.subject &&
        personId == other.personId &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, subject.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuditActor')
          ..add('kind', kind)
          ..add('subject', subject)
          ..add('personId', personId)
          ..add('displayName', displayName))
        .toString();
  }
}

class AuditActorBuilder implements Builder<AuditActor, AuditActorBuilder> {
  _$AuditActor? _$v;

  AuditActorKind? _kind;
  AuditActorKind? get kind => _$this._kind;
  set kind(AuditActorKind? kind) => _$this._kind = kind;

  String? _subject;
  String? get subject => _$this._subject;
  set subject(String? subject) => _$this._subject = subject;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  AuditActorBuilder() {
    AuditActor._defaults(this);
  }

  AuditActorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _kind = $v.kind;
      _subject = $v.subject;
      _personId = $v.personId;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditActor other) {
    _$v = other as _$AuditActor;
  }

  @override
  void update(void Function(AuditActorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditActor build() => _build();

  _$AuditActor _build() {
    final _$result = _$v ??
        _$AuditActor._(
          kind: BuiltValueNullFieldError.checkNotNull(
              kind, r'AuditActor', 'kind'),
          subject: BuiltValueNullFieldError.checkNotNull(
              subject, r'AuditActor', 'subject'),
          personId: personId,
          displayName: displayName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
