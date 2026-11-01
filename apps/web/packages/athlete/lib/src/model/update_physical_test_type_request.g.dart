// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_physical_test_type_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePhysicalTestTypeRequest extends UpdatePhysicalTestTypeRequest {
  @override
  final String? name;
  @override
  final String? unit;
  @override
  final bool? higherIsBetter;
  @override
  final String? description;

  factory _$UpdatePhysicalTestTypeRequest(
          [void Function(UpdatePhysicalTestTypeRequestBuilder)? updates]) =>
      (UpdatePhysicalTestTypeRequestBuilder()..update(updates))._build();

  _$UpdatePhysicalTestTypeRequest._(
      {this.name, this.unit, this.higherIsBetter, this.description})
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
        name == other.name &&
        unit == other.unit &&
        higherIsBetter == other.higherIsBetter &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, higherIsBetter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePhysicalTestTypeRequest')
          ..add('name', name)
          ..add('unit', unit)
          ..add('higherIsBetter', higherIsBetter)
          ..add('description', description))
        .toString();
  }
}

class UpdatePhysicalTestTypeRequestBuilder
    implements
        Builder<UpdatePhysicalTestTypeRequest,
            UpdatePhysicalTestTypeRequestBuilder> {
  _$UpdatePhysicalTestTypeRequest? _$v;

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

  UpdatePhysicalTestTypeRequestBuilder() {
    UpdatePhysicalTestTypeRequest._defaults(this);
  }

  UpdatePhysicalTestTypeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _unit = $v.unit;
      _higherIsBetter = $v.higherIsBetter;
      _description = $v.description;
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
    final _$result = _$v ??
        _$UpdatePhysicalTestTypeRequest._(
          name: name,
          unit: unit,
          higherIsBetter: higherIsBetter,
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
