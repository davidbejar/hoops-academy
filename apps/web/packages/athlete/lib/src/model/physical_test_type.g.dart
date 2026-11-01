// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestType extends PhysicalTestType {
  @override
  final bool global;
  @override
  final String id;
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

  factory _$PhysicalTestType(
          [void Function(PhysicalTestTypeBuilder)? updates]) =>
      (PhysicalTestTypeBuilder()..update(updates))._build();

  _$PhysicalTestType._(
      {required this.global,
      required this.id,
      required this.code,
      required this.name,
      required this.unit,
      required this.higherIsBetter,
      this.description})
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
        global == other.global &&
        id == other.id &&
        code == other.code &&
        name == other.name &&
        unit == other.unit &&
        higherIsBetter == other.higherIsBetter &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, global.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, higherIsBetter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhysicalTestType')
          ..add('global', global)
          ..add('id', id)
          ..add('code', code)
          ..add('name', name)
          ..add('unit', unit)
          ..add('higherIsBetter', higherIsBetter)
          ..add('description', description))
        .toString();
  }
}

class PhysicalTestTypeBuilder
    implements
        Builder<PhysicalTestType, PhysicalTestTypeBuilder>,
        PhysicalTestTypeInputBuilder {
  _$PhysicalTestType? _$v;

  bool? _global;
  bool? get global => _$this._global;
  set global(covariant bool? global) => _$this._global = global;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  String? _code;
  String? get code => _$this._code;
  set code(covariant String? code) => _$this._code = code;

  String? _name;
  String? get name => _$this._name;
  set name(covariant String? name) => _$this._name = name;

  String? _unit;
  String? get unit => _$this._unit;
  set unit(covariant String? unit) => _$this._unit = unit;

  bool? _higherIsBetter;
  bool? get higherIsBetter => _$this._higherIsBetter;
  set higherIsBetter(covariant bool? higherIsBetter) =>
      _$this._higherIsBetter = higherIsBetter;

  String? _description;
  String? get description => _$this._description;
  set description(covariant String? description) =>
      _$this._description = description;

  PhysicalTestTypeBuilder() {
    PhysicalTestType._defaults(this);
  }

  PhysicalTestTypeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _global = $v.global;
      _id = $v.id;
      _code = $v.code;
      _name = $v.name;
      _unit = $v.unit;
      _higherIsBetter = $v.higherIsBetter;
      _description = $v.description;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant PhysicalTestType other) {
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
          global: BuiltValueNullFieldError.checkNotNull(
              global, r'PhysicalTestType', 'global'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PhysicalTestType', 'id'),
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'PhysicalTestType', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'PhysicalTestType', 'name'),
          unit: BuiltValueNullFieldError.checkNotNull(
              unit, r'PhysicalTestType', 'unit'),
          higherIsBetter: BuiltValueNullFieldError.checkNotNull(
              higherIsBetter, r'PhysicalTestType', 'higherIsBetter'),
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
