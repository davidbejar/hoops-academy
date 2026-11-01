// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_injury_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateInjuryRequest extends CreateInjuryRequest {
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

  factory _$CreateInjuryRequest(
          [void Function(CreateInjuryRequestBuilder)? updates]) =>
      (CreateInjuryRequestBuilder()..update(updates))._build();

  _$CreateInjuryRequest._(
      {required this.playerId,
      required this.occurredOn,
      required this.bodyPart,
      required this.severity,
      this.description,
      this.expectedReturnOn})
      : super._();
  @override
  CreateInjuryRequest rebuild(
          void Function(CreateInjuryRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateInjuryRequestBuilder toBuilder() =>
      CreateInjuryRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateInjuryRequest &&
        playerId == other.playerId &&
        occurredOn == other.occurredOn &&
        bodyPart == other.bodyPart &&
        severity == other.severity &&
        description == other.description &&
        expectedReturnOn == other.expectedReturnOn;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, occurredOn.hashCode);
    _$hash = $jc(_$hash, bodyPart.hashCode);
    _$hash = $jc(_$hash, severity.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, expectedReturnOn.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateInjuryRequest')
          ..add('playerId', playerId)
          ..add('occurredOn', occurredOn)
          ..add('bodyPart', bodyPart)
          ..add('severity', severity)
          ..add('description', description)
          ..add('expectedReturnOn', expectedReturnOn))
        .toString();
  }
}

class CreateInjuryRequestBuilder
    implements Builder<CreateInjuryRequest, CreateInjuryRequestBuilder> {
  _$CreateInjuryRequest? _$v;

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

  CreateInjuryRequestBuilder() {
    CreateInjuryRequest._defaults(this);
  }

  CreateInjuryRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _occurredOn = $v.occurredOn;
      _bodyPart = $v.bodyPart;
      _severity = $v.severity;
      _description = $v.description;
      _expectedReturnOn = $v.expectedReturnOn;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateInjuryRequest other) {
    _$v = other as _$CreateInjuryRequest;
  }

  @override
  void update(void Function(CreateInjuryRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateInjuryRequest build() => _build();

  _$CreateInjuryRequest _build() {
    final _$result = _$v ??
        _$CreateInjuryRequest._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'CreateInjuryRequest', 'playerId'),
          occurredOn: BuiltValueNullFieldError.checkNotNull(
              occurredOn, r'CreateInjuryRequest', 'occurredOn'),
          bodyPart: BuiltValueNullFieldError.checkNotNull(
              bodyPart, r'CreateInjuryRequest', 'bodyPart'),
          severity: BuiltValueNullFieldError.checkNotNull(
              severity, r'CreateInjuryRequest', 'severity'),
          description: description,
          expectedReturnOn: expectedReturnOn,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
