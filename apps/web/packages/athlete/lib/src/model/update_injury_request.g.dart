// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_injury_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateInjuryRequest extends UpdateInjuryRequest {
  @override
  final Date? occurredOn;
  @override
  final String? bodyPart;
  @override
  final InjurySeverity? severity;
  @override
  final String? description;
  @override
  final Date? expectedReturnOn;
  @override
  final Date? actualReturnOn;
  @override
  final InjuryStatus? status;

  factory _$UpdateInjuryRequest(
          [void Function(UpdateInjuryRequestBuilder)? updates]) =>
      (UpdateInjuryRequestBuilder()..update(updates))._build();

  _$UpdateInjuryRequest._(
      {this.occurredOn,
      this.bodyPart,
      this.severity,
      this.description,
      this.expectedReturnOn,
      this.actualReturnOn,
      this.status})
      : super._();
  @override
  UpdateInjuryRequest rebuild(
          void Function(UpdateInjuryRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateInjuryRequestBuilder toBuilder() =>
      UpdateInjuryRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateInjuryRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateInjuryRequest')
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

class UpdateInjuryRequestBuilder
    implements Builder<UpdateInjuryRequest, UpdateInjuryRequestBuilder> {
  _$UpdateInjuryRequest? _$v;

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

  UpdateInjuryRequestBuilder() {
    UpdateInjuryRequest._defaults(this);
  }

  UpdateInjuryRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(UpdateInjuryRequest other) {
    _$v = other as _$UpdateInjuryRequest;
  }

  @override
  void update(void Function(UpdateInjuryRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateInjuryRequest build() => _build();

  _$UpdateInjuryRequest _build() {
    final _$result = _$v ??
        _$UpdateInjuryRequest._(
          occurredOn: occurredOn,
          bodyPart: bodyPart,
          severity: severity,
          description: description,
          expectedReturnOn: expectedReturnOn,
          actualReturnOn: actualReturnOn,
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
