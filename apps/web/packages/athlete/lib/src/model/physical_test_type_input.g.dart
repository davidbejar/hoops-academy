// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_type_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class PhysicalTestTypeInputBuilder {
  void replace(PhysicalTestTypeInput other);
  void update(void Function(PhysicalTestTypeInputBuilder) updates);
  String? get code;
  set code(String? code);

  String? get name;
  set name(String? name);

  String? get unit;
  set unit(String? unit);

  bool? get higherIsBetter;
  set higherIsBetter(bool? higherIsBetter);

  String? get description;
  set description(String? description);
}

class _$$PhysicalTestTypeInput extends $PhysicalTestTypeInput {
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

  factory _$$PhysicalTestTypeInput(
          [void Function($PhysicalTestTypeInputBuilder)? updates]) =>
      ($PhysicalTestTypeInputBuilder()..update(updates))._build();

  _$$PhysicalTestTypeInput._(
      {required this.code,
      required this.name,
      required this.unit,
      required this.higherIsBetter,
      this.description})
      : super._();
  @override
  $PhysicalTestTypeInput rebuild(
          void Function($PhysicalTestTypeInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $PhysicalTestTypeInputBuilder toBuilder() =>
      $PhysicalTestTypeInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $PhysicalTestTypeInput &&
        code == other.code &&
        name == other.name &&
        unit == other.unit &&
        higherIsBetter == other.higherIsBetter &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
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
    return (newBuiltValueToStringHelper(r'$PhysicalTestTypeInput')
          ..add('code', code)
          ..add('name', name)
          ..add('unit', unit)
          ..add('higherIsBetter', higherIsBetter)
          ..add('description', description))
        .toString();
  }
}

class $PhysicalTestTypeInputBuilder
    implements
        Builder<$PhysicalTestTypeInput, $PhysicalTestTypeInputBuilder>,
        PhysicalTestTypeInputBuilder {
  _$$PhysicalTestTypeInput? _$v;

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

  $PhysicalTestTypeInputBuilder() {
    $PhysicalTestTypeInput._defaults(this);
  }

  $PhysicalTestTypeInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(covariant $PhysicalTestTypeInput other) {
    _$v = other as _$$PhysicalTestTypeInput;
  }

  @override
  void update(void Function($PhysicalTestTypeInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $PhysicalTestTypeInput build() => _build();

  _$$PhysicalTestTypeInput _build() {
    final _$result = _$v ??
        _$$PhysicalTestTypeInput._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'$PhysicalTestTypeInput', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'$PhysicalTestTypeInput', 'name'),
          unit: BuiltValueNullFieldError.checkNotNull(
              unit, r'$PhysicalTestTypeInput', 'unit'),
          higherIsBetter: BuiltValueNullFieldError.checkNotNull(
              higherIsBetter, r'$PhysicalTestTypeInput', 'higherIsBetter'),
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
