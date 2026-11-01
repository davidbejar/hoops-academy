// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_season_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateSeasonRequest extends UpdateSeasonRequest {
  @override
  final String? name;
  @override
  final Date? startsOn;
  @override
  final Date? endsOn;
  @override
  final int? referenceYear;

  factory _$UpdateSeasonRequest(
          [void Function(UpdateSeasonRequestBuilder)? updates]) =>
      (UpdateSeasonRequestBuilder()..update(updates))._build();

  _$UpdateSeasonRequest._(
      {this.name, this.startsOn, this.endsOn, this.referenceYear})
      : super._();
  @override
  UpdateSeasonRequest rebuild(
          void Function(UpdateSeasonRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateSeasonRequestBuilder toBuilder() =>
      UpdateSeasonRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateSeasonRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateSeasonRequest')
          ..add('name', name)
          ..add('startsOn', startsOn)
          ..add('endsOn', endsOn)
          ..add('referenceYear', referenceYear))
        .toString();
  }
}

class UpdateSeasonRequestBuilder
    implements Builder<UpdateSeasonRequest, UpdateSeasonRequestBuilder> {
  _$UpdateSeasonRequest? _$v;

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

  UpdateSeasonRequestBuilder() {
    UpdateSeasonRequest._defaults(this);
  }

  UpdateSeasonRequestBuilder get _$this {
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
  void replace(UpdateSeasonRequest other) {
    _$v = other as _$UpdateSeasonRequest;
  }

  @override
  void update(void Function(UpdateSeasonRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateSeasonRequest build() => _build();

  _$UpdateSeasonRequest _build() {
    final _$result = _$v ??
        _$UpdateSeasonRequest._(
          name: name,
          startsOn: startsOn,
          endsOn: endsOn,
          referenceYear: referenceYear,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
