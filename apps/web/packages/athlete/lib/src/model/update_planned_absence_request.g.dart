// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_planned_absence_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePlannedAbsenceRequestClearEnum
    _$updatePlannedAbsenceRequestClearEnum_reason =
    const UpdatePlannedAbsenceRequestClearEnum._('reason');
const UpdatePlannedAbsenceRequestClearEnum
    _$updatePlannedAbsenceRequestClearEnum_unknownDefaultOpenApi =
    const UpdatePlannedAbsenceRequestClearEnum._('unknownDefaultOpenApi');

UpdatePlannedAbsenceRequestClearEnum
    _$updatePlannedAbsenceRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'reason':
      return _$updatePlannedAbsenceRequestClearEnum_reason;
    case 'unknownDefaultOpenApi':
      return _$updatePlannedAbsenceRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updatePlannedAbsenceRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdatePlannedAbsenceRequestClearEnum>
    _$updatePlannedAbsenceRequestClearEnumValues = BuiltSet<
        UpdatePlannedAbsenceRequestClearEnum>(const <UpdatePlannedAbsenceRequestClearEnum>[
  _$updatePlannedAbsenceRequestClearEnum_reason,
  _$updatePlannedAbsenceRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdatePlannedAbsenceRequestClearEnum>
    _$updatePlannedAbsenceRequestClearEnumSerializer =
    _$UpdatePlannedAbsenceRequestClearEnumSerializer();

class _$UpdatePlannedAbsenceRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdatePlannedAbsenceRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'reason': 'reason',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'reason': 'reason',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdatePlannedAbsenceRequestClearEnum
  ];
  @override
  final String wireName = 'UpdatePlannedAbsenceRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdatePlannedAbsenceRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdatePlannedAbsenceRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdatePlannedAbsenceRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdatePlannedAbsenceRequest extends UpdatePlannedAbsenceRequest {
  @override
  final Date? fromDate;
  @override
  final Date? toDate;
  @override
  final String? reason;
  @override
  final BuiltSet<UpdatePlannedAbsenceRequestClearEnum>? clear;

  factory _$UpdatePlannedAbsenceRequest(
          [void Function(UpdatePlannedAbsenceRequestBuilder)? updates]) =>
      (UpdatePlannedAbsenceRequestBuilder()..update(updates))._build();

  _$UpdatePlannedAbsenceRequest._(
      {this.fromDate, this.toDate, this.reason, this.clear})
      : super._();
  @override
  UpdatePlannedAbsenceRequest rebuild(
          void Function(UpdatePlannedAbsenceRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePlannedAbsenceRequestBuilder toBuilder() =>
      UpdatePlannedAbsenceRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePlannedAbsenceRequest &&
        fromDate == other.fromDate &&
        toDate == other.toDate &&
        reason == other.reason &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fromDate.hashCode);
    _$hash = $jc(_$hash, toDate.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePlannedAbsenceRequest')
          ..add('fromDate', fromDate)
          ..add('toDate', toDate)
          ..add('reason', reason)
          ..add('clear', clear))
        .toString();
  }
}

class UpdatePlannedAbsenceRequestBuilder
    implements
        Builder<UpdatePlannedAbsenceRequest,
            UpdatePlannedAbsenceRequestBuilder> {
  _$UpdatePlannedAbsenceRequest? _$v;

  Date? _fromDate;
  Date? get fromDate => _$this._fromDate;
  set fromDate(Date? fromDate) => _$this._fromDate = fromDate;

  Date? _toDate;
  Date? get toDate => _$this._toDate;
  set toDate(Date? toDate) => _$this._toDate = toDate;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  SetBuilder<UpdatePlannedAbsenceRequestClearEnum>? _clear;
  SetBuilder<UpdatePlannedAbsenceRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdatePlannedAbsenceRequestClearEnum>();
  set clear(SetBuilder<UpdatePlannedAbsenceRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdatePlannedAbsenceRequestBuilder() {
    UpdatePlannedAbsenceRequest._defaults(this);
  }

  UpdatePlannedAbsenceRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fromDate = $v.fromDate;
      _toDate = $v.toDate;
      _reason = $v.reason;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePlannedAbsenceRequest other) {
    _$v = other as _$UpdatePlannedAbsenceRequest;
  }

  @override
  void update(void Function(UpdatePlannedAbsenceRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePlannedAbsenceRequest build() => _build();

  _$UpdatePlannedAbsenceRequest _build() {
    _$UpdatePlannedAbsenceRequest _$result;
    try {
      _$result = _$v ??
          _$UpdatePlannedAbsenceRequest._(
            fromDate: fromDate,
            toDate: toDate,
            reason: reason,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdatePlannedAbsenceRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
