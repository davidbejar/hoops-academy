// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_injury_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateInjuryRequestClearEnum _$updateInjuryRequestClearEnum_description =
    const UpdateInjuryRequestClearEnum._('description');
const UpdateInjuryRequestClearEnum
    _$updateInjuryRequestClearEnum_expectedReturnOn =
    const UpdateInjuryRequestClearEnum._('expectedReturnOn');
const UpdateInjuryRequestClearEnum
    _$updateInjuryRequestClearEnum_actualReturnOn =
    const UpdateInjuryRequestClearEnum._('actualReturnOn');
const UpdateInjuryRequestClearEnum
    _$updateInjuryRequestClearEnum_unknownDefaultOpenApi =
    const UpdateInjuryRequestClearEnum._('unknownDefaultOpenApi');

UpdateInjuryRequestClearEnum _$updateInjuryRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'description':
      return _$updateInjuryRequestClearEnum_description;
    case 'expectedReturnOn':
      return _$updateInjuryRequestClearEnum_expectedReturnOn;
    case 'actualReturnOn':
      return _$updateInjuryRequestClearEnum_actualReturnOn;
    case 'unknownDefaultOpenApi':
      return _$updateInjuryRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateInjuryRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateInjuryRequestClearEnum>
    _$updateInjuryRequestClearEnumValues =
    BuiltSet<UpdateInjuryRequestClearEnum>(const <UpdateInjuryRequestClearEnum>[
  _$updateInjuryRequestClearEnum_description,
  _$updateInjuryRequestClearEnum_expectedReturnOn,
  _$updateInjuryRequestClearEnum_actualReturnOn,
  _$updateInjuryRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateInjuryRequestClearEnum>
    _$updateInjuryRequestClearEnumSerializer =
    _$UpdateInjuryRequestClearEnumSerializer();

class _$UpdateInjuryRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateInjuryRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'description': 'description',
    'expectedReturnOn': 'expectedReturnOn',
    'actualReturnOn': 'actualReturnOn',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'description': 'description',
    'expectedReturnOn': 'expectedReturnOn',
    'actualReturnOn': 'actualReturnOn',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateInjuryRequestClearEnum];
  @override
  final String wireName = 'UpdateInjuryRequestClearEnum';

  @override
  Object serialize(Serializers serializers, UpdateInjuryRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateInjuryRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateInjuryRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

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
  @override
  final BuiltSet<UpdateInjuryRequestClearEnum>? clear;

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
      this.status,
      this.clear})
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
        status == other.status &&
        clear == other.clear;
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
    _$hash = $jc(_$hash, clear.hashCode);
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
          ..add('status', status)
          ..add('clear', clear))
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

  SetBuilder<UpdateInjuryRequestClearEnum>? _clear;
  SetBuilder<UpdateInjuryRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateInjuryRequestClearEnum>();
  set clear(SetBuilder<UpdateInjuryRequestClearEnum>? clear) =>
      _$this._clear = clear;

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
      _clear = $v.clear?.toBuilder();
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
    _$UpdateInjuryRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateInjuryRequest._(
            occurredOn: occurredOn,
            bodyPart: bodyPart,
            severity: severity,
            description: description,
            expectedReturnOn: expectedReturnOn,
            actualReturnOn: actualReturnOn,
            status: status,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateInjuryRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
