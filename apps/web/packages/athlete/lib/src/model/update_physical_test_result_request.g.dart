// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_physical_test_result_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePhysicalTestResultRequestClearEnum
    _$updatePhysicalTestResultRequestClearEnum_notes =
    const UpdatePhysicalTestResultRequestClearEnum._('notes');
const UpdatePhysicalTestResultRequestClearEnum
    _$updatePhysicalTestResultRequestClearEnum_unknownDefaultOpenApi =
    const UpdatePhysicalTestResultRequestClearEnum._('unknownDefaultOpenApi');

UpdatePhysicalTestResultRequestClearEnum
    _$updatePhysicalTestResultRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'notes':
      return _$updatePhysicalTestResultRequestClearEnum_notes;
    case 'unknownDefaultOpenApi':
      return _$updatePhysicalTestResultRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updatePhysicalTestResultRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdatePhysicalTestResultRequestClearEnum>
    _$updatePhysicalTestResultRequestClearEnumValues = BuiltSet<
        UpdatePhysicalTestResultRequestClearEnum>(const <UpdatePhysicalTestResultRequestClearEnum>[
  _$updatePhysicalTestResultRequestClearEnum_notes,
  _$updatePhysicalTestResultRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdatePhysicalTestResultRequestClearEnum>
    _$updatePhysicalTestResultRequestClearEnumSerializer =
    _$UpdatePhysicalTestResultRequestClearEnumSerializer();

class _$UpdatePhysicalTestResultRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdatePhysicalTestResultRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'notes': 'notes',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'notes': 'notes',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdatePhysicalTestResultRequestClearEnum
  ];
  @override
  final String wireName = 'UpdatePhysicalTestResultRequestClearEnum';

  @override
  Object serialize(Serializers serializers,
          UpdatePhysicalTestResultRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdatePhysicalTestResultRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdatePhysicalTestResultRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdatePhysicalTestResultRequest
    extends UpdatePhysicalTestResultRequest {
  @override
  final Date? measuredOn;
  @override
  final double? value;
  @override
  final String? notes;
  @override
  final BuiltSet<UpdatePhysicalTestResultRequestClearEnum>? clear;

  factory _$UpdatePhysicalTestResultRequest(
          [void Function(UpdatePhysicalTestResultRequestBuilder)? updates]) =>
      (UpdatePhysicalTestResultRequestBuilder()..update(updates))._build();

  _$UpdatePhysicalTestResultRequest._(
      {this.measuredOn, this.value, this.notes, this.clear})
      : super._();
  @override
  UpdatePhysicalTestResultRequest rebuild(
          void Function(UpdatePhysicalTestResultRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePhysicalTestResultRequestBuilder toBuilder() =>
      UpdatePhysicalTestResultRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePhysicalTestResultRequest &&
        measuredOn == other.measuredOn &&
        value == other.value &&
        notes == other.notes &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, measuredOn.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePhysicalTestResultRequest')
          ..add('measuredOn', measuredOn)
          ..add('value', value)
          ..add('notes', notes)
          ..add('clear', clear))
        .toString();
  }
}

class UpdatePhysicalTestResultRequestBuilder
    implements
        Builder<UpdatePhysicalTestResultRequest,
            UpdatePhysicalTestResultRequestBuilder> {
  _$UpdatePhysicalTestResultRequest? _$v;

  Date? _measuredOn;
  Date? get measuredOn => _$this._measuredOn;
  set measuredOn(Date? measuredOn) => _$this._measuredOn = measuredOn;

  double? _value;
  double? get value => _$this._value;
  set value(double? value) => _$this._value = value;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  SetBuilder<UpdatePhysicalTestResultRequestClearEnum>? _clear;
  SetBuilder<UpdatePhysicalTestResultRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdatePhysicalTestResultRequestClearEnum>();
  set clear(SetBuilder<UpdatePhysicalTestResultRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdatePhysicalTestResultRequestBuilder() {
    UpdatePhysicalTestResultRequest._defaults(this);
  }

  UpdatePhysicalTestResultRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _measuredOn = $v.measuredOn;
      _value = $v.value;
      _notes = $v.notes;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePhysicalTestResultRequest other) {
    _$v = other as _$UpdatePhysicalTestResultRequest;
  }

  @override
  void update(void Function(UpdatePhysicalTestResultRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePhysicalTestResultRequest build() => _build();

  _$UpdatePhysicalTestResultRequest _build() {
    _$UpdatePhysicalTestResultRequest _$result;
    try {
      _$result = _$v ??
          _$UpdatePhysicalTestResultRequest._(
            measuredOn: measuredOn,
            value: value,
            notes: notes,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdatePhysicalTestResultRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
