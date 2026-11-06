// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_training_plan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTrainingPlanRequestClearEnum
    _$updateTrainingPlanRequestClearEnum_description =
    const UpdateTrainingPlanRequestClearEnum._('description');
const UpdateTrainingPlanRequestClearEnum
    _$updateTrainingPlanRequestClearEnum_unknownDefaultOpenApi =
    const UpdateTrainingPlanRequestClearEnum._('unknownDefaultOpenApi');

UpdateTrainingPlanRequestClearEnum _$updateTrainingPlanRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'description':
      return _$updateTrainingPlanRequestClearEnum_description;
    case 'unknownDefaultOpenApi':
      return _$updateTrainingPlanRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateTrainingPlanRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateTrainingPlanRequestClearEnum>
    _$updateTrainingPlanRequestClearEnumValues = BuiltSet<
        UpdateTrainingPlanRequestClearEnum>(const <UpdateTrainingPlanRequestClearEnum>[
  _$updateTrainingPlanRequestClearEnum_description,
  _$updateTrainingPlanRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateTrainingPlanRequestClearEnum>
    _$updateTrainingPlanRequestClearEnumSerializer =
    _$UpdateTrainingPlanRequestClearEnumSerializer();

class _$UpdateTrainingPlanRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateTrainingPlanRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'description': 'description',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'description': 'description',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTrainingPlanRequestClearEnum];
  @override
  final String wireName = 'UpdateTrainingPlanRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateTrainingPlanRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateTrainingPlanRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateTrainingPlanRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateTrainingPlanRequest extends UpdateTrainingPlanRequest {
  @override
  final String? name;
  @override
  final String? description;
  @override
  final BuiltSet<UpdateTrainingPlanRequestClearEnum>? clear;

  factory _$UpdateTrainingPlanRequest(
          [void Function(UpdateTrainingPlanRequestBuilder)? updates]) =>
      (UpdateTrainingPlanRequestBuilder()..update(updates))._build();

  _$UpdateTrainingPlanRequest._({this.name, this.description, this.clear})
      : super._();
  @override
  UpdateTrainingPlanRequest rebuild(
          void Function(UpdateTrainingPlanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTrainingPlanRequestBuilder toBuilder() =>
      UpdateTrainingPlanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTrainingPlanRequest &&
        name == other.name &&
        description == other.description &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTrainingPlanRequest')
          ..add('name', name)
          ..add('description', description)
          ..add('clear', clear))
        .toString();
  }
}

class UpdateTrainingPlanRequestBuilder
    implements
        Builder<UpdateTrainingPlanRequest, UpdateTrainingPlanRequestBuilder> {
  _$UpdateTrainingPlanRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  SetBuilder<UpdateTrainingPlanRequestClearEnum>? _clear;
  SetBuilder<UpdateTrainingPlanRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateTrainingPlanRequestClearEnum>();
  set clear(SetBuilder<UpdateTrainingPlanRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateTrainingPlanRequestBuilder() {
    UpdateTrainingPlanRequest._defaults(this);
  }

  UpdateTrainingPlanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTrainingPlanRequest other) {
    _$v = other as _$UpdateTrainingPlanRequest;
  }

  @override
  void update(void Function(UpdateTrainingPlanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTrainingPlanRequest build() => _build();

  _$UpdateTrainingPlanRequest _build() {
    _$UpdateTrainingPlanRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateTrainingPlanRequest._(
            name: name,
            description: description,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdateTrainingPlanRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
