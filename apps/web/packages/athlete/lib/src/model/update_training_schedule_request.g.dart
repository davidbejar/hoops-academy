// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_training_schedule_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTrainingScheduleRequestClearEnum
    _$updateTrainingScheduleRequestClearEnum_location =
    const UpdateTrainingScheduleRequestClearEnum._('location');
const UpdateTrainingScheduleRequestClearEnum
    _$updateTrainingScheduleRequestClearEnum_validUntil =
    const UpdateTrainingScheduleRequestClearEnum._('validUntil');
const UpdateTrainingScheduleRequestClearEnum
    _$updateTrainingScheduleRequestClearEnum_unknownDefaultOpenApi =
    const UpdateTrainingScheduleRequestClearEnum._('unknownDefaultOpenApi');

UpdateTrainingScheduleRequestClearEnum
    _$updateTrainingScheduleRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'location':
      return _$updateTrainingScheduleRequestClearEnum_location;
    case 'validUntil':
      return _$updateTrainingScheduleRequestClearEnum_validUntil;
    case 'unknownDefaultOpenApi':
      return _$updateTrainingScheduleRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateTrainingScheduleRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTrainingScheduleRequestClearEnum>
    _$updateTrainingScheduleRequestClearEnumValues = BuiltSet<
        UpdateTrainingScheduleRequestClearEnum>(const <UpdateTrainingScheduleRequestClearEnum>[
  _$updateTrainingScheduleRequestClearEnum_location,
  _$updateTrainingScheduleRequestClearEnum_validUntil,
  _$updateTrainingScheduleRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateTrainingScheduleRequestClearEnum>
    _$updateTrainingScheduleRequestClearEnumSerializer =
    _$UpdateTrainingScheduleRequestClearEnumSerializer();

class _$UpdateTrainingScheduleRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateTrainingScheduleRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'location': 'location',
    'validUntil': 'validUntil',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'location': 'location',
    'validUntil': 'validUntil',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdateTrainingScheduleRequestClearEnum
  ];
  @override
  final String wireName = 'UpdateTrainingScheduleRequestClearEnum';

  @override
  Object serialize(Serializers serializers,
          UpdateTrainingScheduleRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTrainingScheduleRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTrainingScheduleRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTrainingScheduleRequest extends UpdateTrainingScheduleRequest {
  @override
  final DayOfWeek? dayOfWeek;
  @override
  final String? startTime;
  @override
  final int? durationMinutes;
  @override
  final String? location;
  @override
  final Date? validFrom;
  @override
  final Date? validUntil;
  @override
  final BuiltSet<UpdateTrainingScheduleRequestClearEnum>? clear;

  factory _$UpdateTrainingScheduleRequest(
          [void Function(UpdateTrainingScheduleRequestBuilder)? updates]) =>
      (UpdateTrainingScheduleRequestBuilder()..update(updates))._build();

  _$UpdateTrainingScheduleRequest._(
      {this.dayOfWeek,
      this.startTime,
      this.durationMinutes,
      this.location,
      this.validFrom,
      this.validUntil,
      this.clear})
      : super._();
  @override
  UpdateTrainingScheduleRequest rebuild(
          void Function(UpdateTrainingScheduleRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTrainingScheduleRequestBuilder toBuilder() =>
      UpdateTrainingScheduleRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTrainingScheduleRequest &&
        dayOfWeek == other.dayOfWeek &&
        startTime == other.startTime &&
        durationMinutes == other.durationMinutes &&
        location == other.location &&
        validFrom == other.validFrom &&
        validUntil == other.validUntil &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dayOfWeek.hashCode);
    _$hash = $jc(_$hash, startTime.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, validFrom.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTrainingScheduleRequest')
          ..add('dayOfWeek', dayOfWeek)
          ..add('startTime', startTime)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('validFrom', validFrom)
          ..add('validUntil', validUntil)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateTrainingScheduleRequestBuilder
    implements
        Builder<UpdateTrainingScheduleRequest,
            UpdateTrainingScheduleRequestBuilder> {
  _$UpdateTrainingScheduleRequest? _$v;

  DayOfWeek? _dayOfWeek;
  DayOfWeek? get dayOfWeek => _$this._dayOfWeek;
  set dayOfWeek(DayOfWeek? dayOfWeek) => _$this._dayOfWeek = dayOfWeek;

  String? _startTime;
  String? get startTime => _$this._startTime;
  set startTime(String? startTime) => _$this._startTime = startTime;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  String? _location;
  String? get location => _$this._location;
  set location(String? location) => _$this._location = location;

  Date? _validFrom;
  Date? get validFrom => _$this._validFrom;
  set validFrom(Date? validFrom) => _$this._validFrom = validFrom;

  Date? _validUntil;
  Date? get validUntil => _$this._validUntil;
  set validUntil(Date? validUntil) => _$this._validUntil = validUntil;

  SetBuilder<UpdateTrainingScheduleRequestClearEnum>? _clear;
  SetBuilder<UpdateTrainingScheduleRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateTrainingScheduleRequestClearEnum>();
  set clear(SetBuilder<UpdateTrainingScheduleRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateTrainingScheduleRequestBuilder() {
    UpdateTrainingScheduleRequest._defaults(this);
  }

  UpdateTrainingScheduleRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dayOfWeek = $v.dayOfWeek;
      _startTime = $v.startTime;
      _durationMinutes = $v.durationMinutes;
      _location = $v.location;
      _validFrom = $v.validFrom;
      _validUntil = $v.validUntil;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTrainingScheduleRequest other) {
    _$v = other as _$UpdateTrainingScheduleRequest;
  }

  @override
  void update(void Function(UpdateTrainingScheduleRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTrainingScheduleRequest build() => _build();

  _$UpdateTrainingScheduleRequest _build() {
    _$UpdateTrainingScheduleRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateTrainingScheduleRequest._(
            dayOfWeek: dayOfWeek,
            startTime: startTime,
            durationMinutes: durationMinutes,
            location: location,
            validFrom: validFrom,
            validUntil: validUntil,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateTrainingScheduleRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
