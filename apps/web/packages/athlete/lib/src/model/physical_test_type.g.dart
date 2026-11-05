// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestType extends PhysicalTestType {
  @override
  final String code;
  @override
  final String name;
  @override
  final String unit;
  @override
  final bool higherIsBetter;
  @override
  final String? description;
  @override
  final String id;
  @override
  final bool global;

  factory _$PhysicalTestType(
          [void Function(PhysicalTestTypeBuilder)? updates]) =>
      (PhysicalTestTypeBuilder()..update(updates))._build();

  _$PhysicalTestType._(
      {required this.code,
      required this.name,
      required this.unit,
      required this.higherIsBetter,
      this.description,
      required this.id,
      required this.global})
      : super._();
  @override
  PhysicalTestType rebuild(void Function(PhysicalTestTypeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhysicalTestTypeBuilder toBuilder() =>
      PhysicalTestTypeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhysicalTestType &&
        code == other.code &&
        name == other.name &&
        unit == other.unit &&
        higherIsBetter == other.higherIsBetter &&
        description == other.description &&
        id == other.id &&
        global == other.global;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, higherIsBetter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, global.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhysicalTestType')
          ..add('code', code)
          ..add('name', name)
          ..add('unit', unit)
          ..add('higherIsBetter', higherIsBetter)
          ..add('description', description)
          ..add('id', id)
          ..add('global', global))
        .toString();
  }
}

class PhysicalTestTypeBuilder
    implements Builder<PhysicalTestType, PhysicalTestTypeBuilder> {
  _$PhysicalTestType? _$v;

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

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  bool? _global;
  bool? get global => _$this._global;
  set global(bool? global) => _$this._global = global;

  PhysicalTestTypeBuilder() {
    PhysicalTestType._defaults(this);
  }

  PhysicalTestTypeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _name = $v.name;
      _unit = $v.unit;
      _higherIsBetter = $v.higherIsBetter;
      _description = $v.description;
      _id = $v.id;
      _global = $v.global;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhysicalTestType other) {
    _$v = other as _$PhysicalTestType;
  }

  @override
  void update(void Function(PhysicalTestTypeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhysicalTestType build() => _build();

  _$PhysicalTestType _build() {
    final _$result = _$v ??
        _$PhysicalTestType._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'PhysicalTestType', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'PhysicalTestType', 'name'),
          unit: BuiltValueNullFieldError.checkNotNull(
              unit, r'PhysicalTestType', 'unit'),
          higherIsBetter: BuiltValueNullFieldError.checkNotNull(
              higherIsBetter, r'PhysicalTestType', 'higherIsBetter'),
          description: description,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PhysicalTestType', 'id'),
          global: BuiltValueNullFieldError.checkNotNull(
              global, r'PhysicalTestType', 'global'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
