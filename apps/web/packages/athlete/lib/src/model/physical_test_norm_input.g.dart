// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_norm_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract class PhysicalTestNormInputBuilder {
  void replace(PhysicalTestNormInput other);
  void update(void Function(PhysicalTestNormInputBuilder) updates);
  String? get testTypeId;
  set testTypeId(String? testTypeId);

  Gender? get gender;
  set gender(Gender? gender);

  int? get minAge;
  set minAge(int? minAge);

  int? get maxAge;
  set maxAge(int? maxAge);

  NormBand? get band;
  set band(NormBand? band);

  double? get minValue;
  set minValue(double? minValue);

  double? get maxValue;
  set maxValue(double? maxValue);

  String? get source_;
  set source_(String? source_);
}

class _$$PhysicalTestNormInput extends $PhysicalTestNormInput {
  @override
  final String testTypeId;
  @override
  final Gender gender;
  @override
  final int minAge;
  @override
  final int maxAge;
  @override
  final NormBand band;
  @override
  final double? minValue;
  @override
  final double? maxValue;
  @override
  final String? source_;

  factory _$$PhysicalTestNormInput(
          [void Function($PhysicalTestNormInputBuilder)? updates]) =>
      ($PhysicalTestNormInputBuilder()..update(updates))._build();

  _$$PhysicalTestNormInput._(
      {required this.testTypeId,
      required this.gender,
      required this.minAge,
      required this.maxAge,
      required this.band,
      this.minValue,
      this.maxValue,
      this.source_})
      : super._();
  @override
  $PhysicalTestNormInput rebuild(
          void Function($PhysicalTestNormInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $PhysicalTestNormInputBuilder toBuilder() =>
      $PhysicalTestNormInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $PhysicalTestNormInput &&
        testTypeId == other.testTypeId &&
        gender == other.gender &&
        minAge == other.minAge &&
        maxAge == other.maxAge &&
        band == other.band &&
        minValue == other.minValue &&
        maxValue == other.maxValue &&
        source_ == other.source_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, testTypeId.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, minAge.hashCode);
    _$hash = $jc(_$hash, maxAge.hashCode);
    _$hash = $jc(_$hash, band.hashCode);
    _$hash = $jc(_$hash, minValue.hashCode);
    _$hash = $jc(_$hash, maxValue.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$PhysicalTestNormInput')
          ..add('testTypeId', testTypeId)
          ..add('gender', gender)
          ..add('minAge', minAge)
          ..add('maxAge', maxAge)
          ..add('band', band)
          ..add('minValue', minValue)
          ..add('maxValue', maxValue)
          ..add('source_', source_))
        .toString();
  }
}

class $PhysicalTestNormInputBuilder
    implements
        Builder<$PhysicalTestNormInput, $PhysicalTestNormInputBuilder>,
        PhysicalTestNormInputBuilder {
  _$$PhysicalTestNormInput? _$v;

  String? _testTypeId;
  String? get testTypeId => _$this._testTypeId;
  set testTypeId(covariant String? testTypeId) =>
      _$this._testTypeId = testTypeId;

  Gender? _gender;
  Gender? get gender => _$this._gender;
  set gender(covariant Gender? gender) => _$this._gender = gender;

  int? _minAge;
  int? get minAge => _$this._minAge;
  set minAge(covariant int? minAge) => _$this._minAge = minAge;

  int? _maxAge;
  int? get maxAge => _$this._maxAge;
  set maxAge(covariant int? maxAge) => _$this._maxAge = maxAge;

  NormBand? _band;
  NormBand? get band => _$this._band;
  set band(covariant NormBand? band) => _$this._band = band;

  double? _minValue;
  double? get minValue => _$this._minValue;
  set minValue(covariant double? minValue) => _$this._minValue = minValue;

  double? _maxValue;
  double? get maxValue => _$this._maxValue;
  set maxValue(covariant double? maxValue) => _$this._maxValue = maxValue;

  String? _source_;
  String? get source_ => _$this._source_;
  set source_(covariant String? source_) => _$this._source_ = source_;

  $PhysicalTestNormInputBuilder() {
    $PhysicalTestNormInput._defaults(this);
  }

  $PhysicalTestNormInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _testTypeId = $v.testTypeId;
      _gender = $v.gender;
      _minAge = $v.minAge;
      _maxAge = $v.maxAge;
      _band = $v.band;
      _minValue = $v.minValue;
      _maxValue = $v.maxValue;
      _source_ = $v.source_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $PhysicalTestNormInput other) {
    _$v = other as _$$PhysicalTestNormInput;
  }

  @override
  void update(void Function($PhysicalTestNormInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $PhysicalTestNormInput build() => _build();

  _$$PhysicalTestNormInput _build() {
    final _$result = _$v ??
        _$$PhysicalTestNormInput._(
          testTypeId: BuiltValueNullFieldError.checkNotNull(
              testTypeId, r'$PhysicalTestNormInput', 'testTypeId'),
          gender: BuiltValueNullFieldError.checkNotNull(
              gender, r'$PhysicalTestNormInput', 'gender'),
          minAge: BuiltValueNullFieldError.checkNotNull(
              minAge, r'$PhysicalTestNormInput', 'minAge'),
          maxAge: BuiltValueNullFieldError.checkNotNull(
              maxAge, r'$PhysicalTestNormInput', 'maxAge'),
          band: BuiltValueNullFieldError.checkNotNull(
              band, r'$PhysicalTestNormInput', 'band'),
          minValue: minValue,
          maxValue: maxValue,
          source_: source_,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
