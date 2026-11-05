// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Season extends Season {
  @override
  final String name;
  @override
  final Date startsOn;
  @override
  final Date endsOn;
  @override
  final int referenceYear;
  @override
  final String id;
  @override
  final bool current;

  factory _$Season([void Function(SeasonBuilder)? updates]) =>
      (SeasonBuilder()..update(updates))._build();

  _$Season._(
      {required this.name,
      required this.startsOn,
      required this.endsOn,
      required this.referenceYear,
      required this.id,
      required this.current})
      : super._();
  @override
  Season rebuild(void Function(SeasonBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeasonBuilder toBuilder() => SeasonBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Season &&
        name == other.name &&
        startsOn == other.startsOn &&
        endsOn == other.endsOn &&
        referenceYear == other.referenceYear &&
        id == other.id &&
        current == other.current;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, startsOn.hashCode);
    _$hash = $jc(_$hash, endsOn.hashCode);
    _$hash = $jc(_$hash, referenceYear.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, current.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Season')
          ..add('name', name)
          ..add('startsOn', startsOn)
          ..add('endsOn', endsOn)
          ..add('referenceYear', referenceYear)
          ..add('id', id)
          ..add('current', current))
        .toString();
  }
}

class SeasonBuilder implements Builder<Season, SeasonBuilder> {
  _$Season? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  Date? _startsOn;
  Date? get startsOn => _$this._startsOn;
  set startsOn(Date? startsOn) => _$this._startsOn = startsOn;

  Date? _endsOn;
  Date? get endsOn => _$this._endsOn;
  set endsOn(Date? endsOn) => _$this._endsOn = endsOn;

  int? _referenceYear;
  int? get referenceYear => _$this._referenceYear;
  set referenceYear(int? referenceYear) =>
      _$this._referenceYear = referenceYear;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  bool? _current;
  bool? get current => _$this._current;
  set current(bool? current) => _$this._current = current;

  SeasonBuilder() {
    Season._defaults(this);
  }

  SeasonBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _startsOn = $v.startsOn;
      _endsOn = $v.endsOn;
      _referenceYear = $v.referenceYear;
      _id = $v.id;
      _current = $v.current;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Season other) {
    _$v = other as _$Season;
  }

  @override
  void update(void Function(SeasonBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Season build() => _build();

  _$Season _build() {
    final _$result = _$v ??
        _$Season._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'Season', 'name'),
          startsOn: BuiltValueNullFieldError.checkNotNull(
              startsOn, r'Season', 'startsOn'),
          endsOn: BuiltValueNullFieldError.checkNotNull(
              endsOn, r'Season', 'endsOn'),
          referenceYear: BuiltValueNullFieldError.checkNotNull(
              referenceYear, r'Season', 'referenceYear'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'Season', 'id'),
          current: BuiltValueNullFieldError.checkNotNull(
              current, r'Season', 'current'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
