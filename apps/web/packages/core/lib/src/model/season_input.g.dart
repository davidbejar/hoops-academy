// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class SeasonInputBuilder {
  void replace(SeasonInput other);
  void update(void Function(SeasonInputBuilder) updates);
  String? get name;
  set name(String? name);

  Date? get startsOn;
  set startsOn(Date? startsOn);

  Date? get endsOn;
  set endsOn(Date? endsOn);

  int? get referenceYear;
  set referenceYear(int? referenceYear);
}

class _$$SeasonInput extends $SeasonInput {
  @override
  final String name;
  @override
  final Date startsOn;
  @override
  final Date endsOn;
  @override
  final int referenceYear;

  factory _$$SeasonInput([void Function($SeasonInputBuilder)? updates]) =>
      ($SeasonInputBuilder()..update(updates))._build();

  _$$SeasonInput._(
      {required this.name,
      required this.startsOn,
      required this.endsOn,
      required this.referenceYear})
      : super._();
  @override
  $SeasonInput rebuild(void Function($SeasonInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $SeasonInputBuilder toBuilder() => $SeasonInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $SeasonInput &&
        name == other.name &&
        startsOn == other.startsOn &&
        endsOn == other.endsOn &&
        referenceYear == other.referenceYear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, startsOn.hashCode);
    _$hash = $jc(_$hash, endsOn.hashCode);
    _$hash = $jc(_$hash, referenceYear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$SeasonInput')
          ..add('name', name)
          ..add('startsOn', startsOn)
          ..add('endsOn', endsOn)
          ..add('referenceYear', referenceYear))
        .toString();
  }
}

class $SeasonInputBuilder
    implements Builder<$SeasonInput, $SeasonInputBuilder>, SeasonInputBuilder {
  _$$SeasonInput? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(covariant String? name) => _$this._name = name;

  Date? _startsOn;
  Date? get startsOn => _$this._startsOn;
  set startsOn(covariant Date? startsOn) => _$this._startsOn = startsOn;

  Date? _endsOn;
  Date? get endsOn => _$this._endsOn;
  set endsOn(covariant Date? endsOn) => _$this._endsOn = endsOn;

  int? _referenceYear;
  int? get referenceYear => _$this._referenceYear;
  set referenceYear(covariant int? referenceYear) =>
      _$this._referenceYear = referenceYear;

  $SeasonInputBuilder() {
    $SeasonInput._defaults(this);
  }

  $SeasonInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _startsOn = $v.startsOn;
      _endsOn = $v.endsOn;
      _referenceYear = $v.referenceYear;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $SeasonInput other) {
    _$v = other as _$$SeasonInput;
  }

  @override
  void update(void Function($SeasonInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $SeasonInput build() => _build();

  _$$SeasonInput _build() {
    final _$result = _$v ??
        _$$SeasonInput._(
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'$SeasonInput', 'name'),
          startsOn: BuiltValueNullFieldError.checkNotNull(
              startsOn, r'$SeasonInput', 'startsOn'),
          endsOn: BuiltValueNullFieldError.checkNotNull(
              endsOn, r'$SeasonInput', 'endsOn'),
          referenceYear: BuiltValueNullFieldError.checkNotNull(
              referenceYear, r'$SeasonInput', 'referenceYear'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
