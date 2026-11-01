// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_test_norm.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhysicalTestNorm extends PhysicalTestNorm {
  @override
  final bool global;
  @override
  final String id;
  @override
  final bool referencePending;
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

  factory _$PhysicalTestNorm(
          [void Function(PhysicalTestNormBuilder)? updates]) =>
      (PhysicalTestNormBuilder()..update(updates))._build();

  _$PhysicalTestNorm._(
      {required this.global,
      required this.id,
      required this.referencePending,
      required this.testTypeId,
      required this.gender,
      required this.minAge,
      required this.maxAge,
      required this.band,
      this.minValue,
      this.maxValue,
      this.source_})
      : super._();
  @override
  PhysicalTestNorm rebuild(void Function(PhysicalTestNormBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhysicalTestNormBuilder toBuilder() =>
      PhysicalTestNormBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhysicalTestNorm &&
        global == other.global &&
        id == other.id &&
        referencePending == other.referencePending &&
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
    _$hash = $jc(_$hash, global.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, referencePending.hashCode);
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
    return (newBuiltValueToStringHelper(r'PhysicalTestNorm')
          ..add('global', global)
          ..add('id', id)
          ..add('referencePending', referencePending)
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

class PhysicalTestNormBuilder
    implements
        Builder<PhysicalTestNorm, PhysicalTestNormBuilder>,
        PhysicalTestNormInputBuilder {
  _$PhysicalTestNorm? _$v;

  bool? _global;
  bool? get global => _$this._global;
  set global(covariant bool? global) => _$this._global = global;

  String? _id;
  String? get id => _$this._id;
  set id(covariant String? id) => _$this._id = id;

  bool? _referencePending;
  bool? get referencePending => _$this._referencePending;
  set referencePending(covariant bool? referencePending) =>
      _$this._referencePending = referencePending;

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

  PhysicalTestNormBuilder() {
    PhysicalTestNorm._defaults(this);
  }

  PhysicalTestNormBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _global = $v.global;
      _id = $v.id;
      _referencePending = $v.referencePending;
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
  void replace(covariant PhysicalTestNorm other) {
    _$v = other as _$PhysicalTestNorm;
  }

  @override
  void update(void Function(PhysicalTestNormBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhysicalTestNorm build() => _build();

  _$PhysicalTestNorm _build() {
    final _$result = _$v ??
        _$PhysicalTestNorm._(
          global: BuiltValueNullFieldError.checkNotNull(
              global, r'PhysicalTestNorm', 'global'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PhysicalTestNorm', 'id'),
          referencePending: BuiltValueNullFieldError.checkNotNull(
              referencePending, r'PhysicalTestNorm', 'referencePending'),
          testTypeId: BuiltValueNullFieldError.checkNotNull(
              testTypeId, r'PhysicalTestNorm', 'testTypeId'),
          gender: BuiltValueNullFieldError.checkNotNull(
              gender, r'PhysicalTestNorm', 'gender'),
          minAge: BuiltValueNullFieldError.checkNotNull(
              minAge, r'PhysicalTestNorm', 'minAge'),
          maxAge: BuiltValueNullFieldError.checkNotNull(
              maxAge, r'PhysicalTestNorm', 'maxAge'),
          band: BuiltValueNullFieldError.checkNotNull(
              band, r'PhysicalTestNorm', 'band'),
          minValue: minValue,
          maxValue: maxValue,
          source_: source_,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
