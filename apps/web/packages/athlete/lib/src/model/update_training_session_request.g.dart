// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_training_session_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTrainingSessionRequestStatusEnum
    _$updateTrainingSessionRequestStatusEnum_PLANNED =
    const UpdateTrainingSessionRequestStatusEnum._('PLANNED');
const UpdateTrainingSessionRequestStatusEnum
    _$updateTrainingSessionRequestStatusEnum_DONE =
    const UpdateTrainingSessionRequestStatusEnum._('DONE');
const UpdateTrainingSessionRequestStatusEnum
    _$updateTrainingSessionRequestStatusEnum_unknownDefaultOpenApi =
    const UpdateTrainingSessionRequestStatusEnum._('unknownDefaultOpenApi');

UpdateTrainingSessionRequestStatusEnum
    _$updateTrainingSessionRequestStatusEnumValueOf(String name) {
  switch (name) {
    case 'PLANNED':
      return _$updateTrainingSessionRequestStatusEnum_PLANNED;
    case 'DONE':
      return _$updateTrainingSessionRequestStatusEnum_DONE;
    case 'unknownDefaultOpenApi':
      return _$updateTrainingSessionRequestStatusEnum_unknownDefaultOpenApi;
    default:
      return _$updateTrainingSessionRequestStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTrainingSessionRequestStatusEnum>
    _$updateTrainingSessionRequestStatusEnumValues = BuiltSet<
        UpdateTrainingSessionRequestStatusEnum>(const <UpdateTrainingSessionRequestStatusEnum>[
  _$updateTrainingSessionRequestStatusEnum_PLANNED,
  _$updateTrainingSessionRequestStatusEnum_DONE,
  _$updateTrainingSessionRequestStatusEnum_unknownDefaultOpenApi,
]);

const UpdateTrainingSessionRequestClearEnum
    _$updateTrainingSessionRequestClearEnum_location =
    const UpdateTrainingSessionRequestClearEnum._('location');
const UpdateTrainingSessionRequestClearEnum
    _$updateTrainingSessionRequestClearEnum_planId =
    const UpdateTrainingSessionRequestClearEnum._('planId');
const UpdateTrainingSessionRequestClearEnum
    _$updateTrainingSessionRequestClearEnum_notes =
    const UpdateTrainingSessionRequestClearEnum._('notes');
const UpdateTrainingSessionRequestClearEnum
    _$updateTrainingSessionRequestClearEnum_unknownDefaultOpenApi =
    const UpdateTrainingSessionRequestClearEnum._('unknownDefaultOpenApi');

UpdateTrainingSessionRequestClearEnum
    _$updateTrainingSessionRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'location':
      return _$updateTrainingSessionRequestClearEnum_location;
    case 'planId':
      return _$updateTrainingSessionRequestClearEnum_planId;
    case 'notes':
      return _$updateTrainingSessionRequestClearEnum_notes;
    case 'unknownDefaultOpenApi':
      return _$updateTrainingSessionRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateTrainingSessionRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTrainingSessionRequestClearEnum>
    _$updateTrainingSessionRequestClearEnumValues = BuiltSet<
        UpdateTrainingSessionRequestClearEnum>(const <UpdateTrainingSessionRequestClearEnum>[
  _$updateTrainingSessionRequestClearEnum_location,
  _$updateTrainingSessionRequestClearEnum_planId,
  _$updateTrainingSessionRequestClearEnum_notes,
  _$updateTrainingSessionRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateTrainingSessionRequestStatusEnum>
    _$updateTrainingSessionRequestStatusEnumSerializer =
    _$UpdateTrainingSessionRequestStatusEnumSerializer();
Serializer<UpdateTrainingSessionRequestClearEnum>
    _$updateTrainingSessionRequestClearEnumSerializer =
    _$UpdateTrainingSessionRequestClearEnumSerializer();

class _$UpdateTrainingSessionRequestStatusEnumSerializer
    implements PrimitiveSerializer<UpdateTrainingSessionRequestStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PLANNED': 'PLANNED',
    'DONE': 'DONE',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PLANNED': 'PLANNED',
    'DONE': 'DONE',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdateTrainingSessionRequestStatusEnum
  ];
  @override
  final String wireName = 'UpdateTrainingSessionRequestStatusEnum';

  @override
  Object serialize(Serializers serializers,
          UpdateTrainingSessionRequestStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTrainingSessionRequestStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTrainingSessionRequestStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTrainingSessionRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateTrainingSessionRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'location': 'location',
    'planId': 'planId',
    'notes': 'notes',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'location': 'location',
    'planId': 'planId',
    'notes': 'notes',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdateTrainingSessionRequestClearEnum
  ];
  @override
  final String wireName = 'UpdateTrainingSessionRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateTrainingSessionRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTrainingSessionRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTrainingSessionRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTrainingSessionRequest extends UpdateTrainingSessionRequest {
  @override
  final DateTime? startsAt;
  @override
  final int? durationMinutes;
  @override
  final String? location;
  @override
  final String? planId;
  @override
  final String? notes;
  @override
  final UpdateTrainingSessionRequestStatusEnum? status;
  @override
  final BuiltSet<UpdateTrainingSessionRequestClearEnum>? clear;

  factory _$UpdateTrainingSessionRequest(
          [void Function(UpdateTrainingSessionRequestBuilder)? updates]) =>
      (UpdateTrainingSessionRequestBuilder()..update(updates))._build();

  _$UpdateTrainingSessionRequest._(
      {this.startsAt,
      this.durationMinutes,
      this.location,
      this.planId,
      this.notes,
      this.status,
      this.clear})
      : super._();
  @override
  UpdateTrainingSessionRequest rebuild(
          void Function(UpdateTrainingSessionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTrainingSessionRequestBuilder toBuilder() =>
      UpdateTrainingSessionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTrainingSessionRequest &&
        startsAt == other.startsAt &&
        durationMinutes == other.durationMinutes &&
        location == other.location &&
        planId == other.planId &&
        notes == other.notes &&
        status == other.status &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, startsAt.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTrainingSessionRequest')
          ..add('startsAt', startsAt)
          ..add('durationMinutes', durationMinutes)
          ..add('location', location)
          ..add('planId', planId)
          ..add('notes', notes)
          ..add('status', status)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateTrainingSessionRequestBuilder
    implements
        Builder<UpdateTrainingSessionRequest,
            UpdateTrainingSessionRequestBuilder> {
  _$UpdateTrainingSessionRequest? _$v;

  DateTime? _startsAt;
  DateTime? get startsAt => _$this._startsAt;
  set startsAt(DateTime? startsAt) => _$this._startsAt = startsAt;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  String? _location;
  String? get location => _$this._location;
  set location(String? location) => _$this._location = location;

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  UpdateTrainingSessionRequestStatusEnum? _status;
  UpdateTrainingSessionRequestStatusEnum? get status => _$this._status;
  set status(UpdateTrainingSessionRequestStatusEnum? status) =>
      _$this._status = status;

  SetBuilder<UpdateTrainingSessionRequestClearEnum>? _clear;
  SetBuilder<UpdateTrainingSessionRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateTrainingSessionRequestClearEnum>();
  set clear(SetBuilder<UpdateTrainingSessionRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateTrainingSessionRequestBuilder() {
    UpdateTrainingSessionRequest._defaults(this);
  }

  UpdateTrainingSessionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _startsAt = $v.startsAt;
      _durationMinutes = $v.durationMinutes;
      _location = $v.location;
      _planId = $v.planId;
      _notes = $v.notes;
      _status = $v.status;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTrainingSessionRequest other) {
    _$v = other as _$UpdateTrainingSessionRequest;
  }

  @override
  void update(void Function(UpdateTrainingSessionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTrainingSessionRequest build() => _build();

  _$UpdateTrainingSessionRequest _build() {
    _$UpdateTrainingSessionRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateTrainingSessionRequest._(
            startsAt: startsAt,
            durationMinutes: durationMinutes,
            location: location,
            planId: planId,
            notes: notes,
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
            r'UpdateTrainingSessionRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
