// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injury.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Injury extends Injury {
  @override
  final InjurySeverity severity;
  @override
  final Date? expectedReturnOn;
  @override
  final Date? actualReturnOn;
  @override
  final String? description;
  @override
  final String id;
  @override
  final Date occurredOn;
  @override
  final String playerId;
  @override
  final String bodyPart;
  @override
  final InjuryStatus status;
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;

  factory _$Injury([void Function(InjuryBuilder)? updates]) =>
      (InjuryBuilder()..update(updates))._build();

  _$Injury._(
      {required this.severity,
      this.expectedReturnOn,
      this.actualReturnOn,
      this.description,
      required this.id,
      required this.occurredOn,
      required this.playerId,
      required this.bodyPart,
      required this.status,
      required this.recordedBy,
      required this.recordedAt})
      : super._();
  @override
  Injury rebuild(void Function(InjuryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InjuryBuilder toBuilder() => InjuryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Injury &&
        severity == other.severity &&
        expectedReturnOn == other.expectedReturnOn &&
        actualReturnOn == other.actualReturnOn &&
        description == other.description &&
        id == other.id &&
        occurredOn == other.occurredOn &&
        playerId == other.playerId &&
        bodyPart == other.bodyPart &&
        status == other.status &&
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, severity.hashCode);
    _$hash = $jc(_$hash, expectedReturnOn.hashCode);
    _$hash = $jc(_$hash, actualReturnOn.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, occurredOn.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, bodyPart.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Injury')
          ..add('severity', severity)
          ..add('expectedReturnOn', expectedReturnOn)
          ..add('actualReturnOn', actualReturnOn)
          ..add('description', description)
          ..add('id', id)
          ..add('occurredOn', occurredOn)
          ..add('playerId', playerId)
          ..add('bodyPart', bodyPart)
          ..add('status', status)
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt))
        .toString();
  }
}

class InjuryBuilder
    implements Builder<Injury, InjuryBuilder>, AuditInfoBuilder {
  _$Injury? _$v;

  InjurySeverity? _severity;
  InjurySeverity? get severity => _$this._severity;
  set severity(covariant InjurySeverity? severity) =>
      _$this._severity = severity;

  Date? _expectedReturnOn;
  Date? get expectedReturnOn => _$this._expectedReturnOn;
  set expectedReturnOn(covariant Date? expectedReturnOn) =>
      _$this._expectedReturnOn = expectedReturnOn;

  Date? _actualReturnOn;
  Date? get actualReturnOn => _$this._actualReturnOn;
  set actualReturnOn(covariant Date? actualReturnOn) =>
      _$this._actualReturnOn = actualReturnOn;

  String? _description;
  String? get description => _$this._description;
  set description(covariant String? description) =>
      _$this._description = description;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  Date? _occurredOn;
  Date? get occurredOn => _$this._occurredOn;
  set occurredOn(covariant Date? occurredOn) => _$this._occurredOn = occurredOn;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(covariant String? playerId) => _$this._playerId = playerId;

  String? _bodyPart;
  String? get bodyPart => _$this._bodyPart;
  set bodyPart(covariant String? bodyPart) => _$this._bodyPart = bodyPart;

  InjuryStatus? _status;
  InjuryStatus? get status => _$this._status;
  set status(covariant InjuryStatus? status) => _$this._status = status;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(covariant PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(covariant DateTime? recordedAt) =>
      _$this._recordedAt = recordedAt;

  InjuryBuilder() {
    Injury._defaults(this);
  }

  InjuryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _severity = $v.severity;
      _expectedReturnOn = $v.expectedReturnOn;
      _actualReturnOn = $v.actualReturnOn;
      _description = $v.description;
      _id = $v.id;
      _occurredOn = $v.occurredOn;
      _playerId = $v.playerId;
      _bodyPart = $v.bodyPart;
      _status = $v.status;
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant Injury other) {
    _$v = other as _$Injury;
  }

  @override
  void update(void Function(InjuryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Injury build() => _build();

  _$Injury _build() {
    _$Injury _$result;
    try {
      _$result = _$v ??
          _$Injury._(
            severity: BuiltValueNullFieldError.checkNotNull(
                severity, r'Injury', 'severity'),
            expectedReturnOn: expectedReturnOn,
            actualReturnOn: actualReturnOn,
            description: description,
            id: BuiltValueNullFieldError.checkNotNull(id, r'Injury', 'id'),
            occurredOn: BuiltValueNullFieldError.checkNotNull(
                occurredOn, r'Injury', 'occurredOn'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'Injury', 'playerId'),
            bodyPart: BuiltValueNullFieldError.checkNotNull(
                bodyPart, r'Injury', 'bodyPart'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'Injury', 'status'),
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'Injury', 'recordedAt'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'recordedBy';
        recordedBy.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Injury', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
