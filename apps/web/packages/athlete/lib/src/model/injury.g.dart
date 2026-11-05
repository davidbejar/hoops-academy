// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'injury.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Injury extends Injury {
  @override
  final PersonRef recordedBy;
  @override
  final DateTime recordedAt;
  @override
  final String id;
  @override
  final String playerId;
  @override
  final Date occurredOn;
  @override
  final String bodyPart;
  @override
  final InjurySeverity severity;
  @override
  final String? description;
  @override
  final Date? expectedReturnOn;
  @override
  final Date? actualReturnOn;
  @override
  final InjuryStatus status;

  factory _$Injury([void Function(InjuryBuilder)? updates]) =>
      (InjuryBuilder()..update(updates))._build();

  _$Injury._(
      {required this.recordedBy,
      required this.recordedAt,
      required this.id,
      required this.playerId,
      required this.occurredOn,
      required this.bodyPart,
      required this.severity,
      this.description,
      this.expectedReturnOn,
      this.actualReturnOn,
      required this.status})
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
        recordedBy == other.recordedBy &&
        recordedAt == other.recordedAt &&
        id == other.id &&
        playerId == other.playerId &&
        occurredOn == other.occurredOn &&
        bodyPart == other.bodyPart &&
        severity == other.severity &&
        description == other.description &&
        expectedReturnOn == other.expectedReturnOn &&
        actualReturnOn == other.actualReturnOn &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, recordedBy.hashCode);
    _$hash = $jc(_$hash, recordedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, occurredOn.hashCode);
    _$hash = $jc(_$hash, bodyPart.hashCode);
    _$hash = $jc(_$hash, severity.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, expectedReturnOn.hashCode);
    _$hash = $jc(_$hash, actualReturnOn.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Injury')
          ..add('recordedBy', recordedBy)
          ..add('recordedAt', recordedAt)
          ..add('id', id)
          ..add('playerId', playerId)
          ..add('occurredOn', occurredOn)
          ..add('bodyPart', bodyPart)
          ..add('severity', severity)
          ..add('description', description)
          ..add('expectedReturnOn', expectedReturnOn)
          ..add('actualReturnOn', actualReturnOn)
          ..add('status', status))
        .toString();
  }
}

class InjuryBuilder implements Builder<Injury, InjuryBuilder> {
  _$Injury? _$v;

  PersonRefBuilder? _recordedBy;
  PersonRefBuilder get recordedBy => _$this._recordedBy ??= PersonRefBuilder();
  set recordedBy(PersonRefBuilder? recordedBy) =>
      _$this._recordedBy = recordedBy;

  DateTime? _recordedAt;
  DateTime? get recordedAt => _$this._recordedAt;
  set recordedAt(DateTime? recordedAt) => _$this._recordedAt = recordedAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  Date? _occurredOn;
  Date? get occurredOn => _$this._occurredOn;
  set occurredOn(Date? occurredOn) => _$this._occurredOn = occurredOn;

  String? _bodyPart;
  String? get bodyPart => _$this._bodyPart;
  set bodyPart(String? bodyPart) => _$this._bodyPart = bodyPart;

  InjurySeverity? _severity;
  InjurySeverity? get severity => _$this._severity;
  set severity(InjurySeverity? severity) => _$this._severity = severity;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  Date? _expectedReturnOn;
  Date? get expectedReturnOn => _$this._expectedReturnOn;
  set expectedReturnOn(Date? expectedReturnOn) =>
      _$this._expectedReturnOn = expectedReturnOn;

  Date? _actualReturnOn;
  Date? get actualReturnOn => _$this._actualReturnOn;
  set actualReturnOn(Date? actualReturnOn) =>
      _$this._actualReturnOn = actualReturnOn;

  InjuryStatus? _status;
  InjuryStatus? get status => _$this._status;
  set status(InjuryStatus? status) => _$this._status = status;

  InjuryBuilder() {
    Injury._defaults(this);
  }

  InjuryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _recordedBy = $v.recordedBy.toBuilder();
      _recordedAt = $v.recordedAt;
      _id = $v.id;
      _playerId = $v.playerId;
      _occurredOn = $v.occurredOn;
      _bodyPart = $v.bodyPart;
      _severity = $v.severity;
      _description = $v.description;
      _expectedReturnOn = $v.expectedReturnOn;
      _actualReturnOn = $v.actualReturnOn;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Injury other) {
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
            recordedBy: recordedBy.build(),
            recordedAt: BuiltValueNullFieldError.checkNotNull(
                recordedAt, r'Injury', 'recordedAt'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'Injury', 'id'),
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'Injury', 'playerId'),
            occurredOn: BuiltValueNullFieldError.checkNotNull(
                occurredOn, r'Injury', 'occurredOn'),
            bodyPart: BuiltValueNullFieldError.checkNotNull(
                bodyPart, r'Injury', 'bodyPart'),
            severity: BuiltValueNullFieldError.checkNotNull(
                severity, r'Injury', 'severity'),
            description: description,
            expectedReturnOn: expectedReturnOn,
            actualReturnOn: actualReturnOn,
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'Injury', 'status'),
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
