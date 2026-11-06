// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_physical_test_type_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePhysicalTestTypeRequestClearEnum
    _$updatePhysicalTestTypeRequestClearEnum_description =
    const UpdatePhysicalTestTypeRequestClearEnum._('description');
const UpdatePhysicalTestTypeRequestClearEnum
    _$updatePhysicalTestTypeRequestClearEnum_unknownDefaultOpenApi =
    const UpdatePhysicalTestTypeRequestClearEnum._('unknownDefaultOpenApi');

UpdatePhysicalTestTypeRequestClearEnum
    _$updatePhysicalTestTypeRequestClearEnumValueOf(String name) {
  switch (name) {
    case 'description':
      return _$updatePhysicalTestTypeRequestClearEnum_description;
    case 'unknownDefaultOpenApi':
      return _$updatePhysicalTestTypeRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updatePhysicalTestTypeRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdatePhysicalTestTypeRequestClearEnum>
    _$updatePhysicalTestTypeRequestClearEnumValues = BuiltSet<
        UpdatePhysicalTestTypeRequestClearEnum>(const <UpdatePhysicalTestTypeRequestClearEnum>[
  _$updatePhysicalTestTypeRequestClearEnum_description,
  _$updatePhysicalTestTypeRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdatePhysicalTestTypeRequestClearEnum>
    _$updatePhysicalTestTypeRequestClearEnumSerializer =
    _$UpdatePhysicalTestTypeRequestClearEnumSerializer();

class _$UpdatePhysicalTestTypeRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdatePhysicalTestTypeRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'description': 'description',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'description': 'description',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    UpdatePhysicalTestTypeRequestClearEnum
  ];
  @override
  final String wireName = 'UpdatePhysicalTestTypeRequestClearEnum';

  @override
  Object serialize(Serializers serializers,
          UpdatePhysicalTestTypeRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdatePhysicalTestTypeRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdatePhysicalTestTypeRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdatePhysicalTestTypeRequest extends UpdatePhysicalTestTypeRequest {
  @override
  final String? code;
  @override
  final String? name;
  @override
  final String? unit;
  @override
  final bool? higherIsBetter;
  @override
  final String? description;
  @override
  final BuiltSet<UpdatePhysicalTestTypeRequestClearEnum>? clear;

  factory _$UpdatePhysicalTestTypeRequest(
          [void Function(UpdatePhysicalTestTypeRequestBuilder)? updates]) =>
      (UpdatePhysicalTestTypeRequestBuilder()..update(updates))._build();

  _$UpdatePhysicalTestTypeRequest._(
      {this.code,
      this.name,
      this.unit,
      this.higherIsBetter,
      this.description,
      this.clear})
      : super._();
  @override
  UpdatePhysicalTestTypeRequest rebuild(
          void Function(UpdatePhysicalTestTypeRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePhysicalTestTypeRequestBuilder toBuilder() =>
      UpdatePhysicalTestTypeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePhysicalTestTypeRequest &&
        code == other.code &&
        name == other.name &&
        unit == other.unit &&
        higherIsBetter == other.higherIsBetter &&
        description == other.description &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, higherIsBetter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePhysicalTestTypeRequest')
          ..add('code', code)
          ..add('name', name)
          ..add('unit', unit)
          ..add('higherIsBetter', higherIsBetter)
          ..add('description', description)
          ..add('clear', clear))
        .toString();
  }
}

class UpdatePhysicalTestTypeRequestBuilder
    implements
        Builder<UpdatePhysicalTestTypeRequest,
            UpdatePhysicalTestTypeRequestBuilder> {
  _$UpdatePhysicalTestTypeRequest? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _unit;
  String? get unit => _$this._unit;
  set unit(String? unit) => _$this._unit = unit;

  bool? _higherIsBetter;
  bool? get higherIsBetter => _$this._higherIsBetter;
  set higherIsBetter(bool? higherIsBetter) =>
      _$this._higherIsBetter = higherIsBetter;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  SetBuilder<UpdatePhysicalTestTypeRequestClearEnum>? _clear;
  SetBuilder<UpdatePhysicalTestTypeRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdatePhysicalTestTypeRequestClearEnum>();
  set clear(SetBuilder<UpdatePhysicalTestTypeRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdatePhysicalTestTypeRequestBuilder() {
    UpdatePhysicalTestTypeRequest._defaults(this);
  }

  UpdatePhysicalTestTypeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _name = $v.name;
      _unit = $v.unit;
      _higherIsBetter = $v.higherIsBetter;
      _description = $v.description;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePhysicalTestTypeRequest other) {
    _$v = other as _$UpdatePhysicalTestTypeRequest;
  }

  @override
  void update(void Function(UpdatePhysicalTestTypeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePhysicalTestTypeRequest build() => _build();

  _$UpdatePhysicalTestTypeRequest _build() {
    _$UpdatePhysicalTestTypeRequest _$result;
    try {
      _$result = _$v ??
          _$UpdatePhysicalTestTypeRequest._(
            code: code,
            name: name,
            unit: unit,
            higherIsBetter: higherIsBetter,
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
            r'UpdatePhysicalTestTypeRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
