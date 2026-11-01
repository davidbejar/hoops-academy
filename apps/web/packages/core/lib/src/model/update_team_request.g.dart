// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_team_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateTeamRequest extends UpdateTeamRequest {
  @override
  final String? name;
  @override
  final String? alias;
  @override
  final String? ageCategoryId;
  @override
  final GenderPolicy? genderPolicy;

  factory _$UpdateTeamRequest(
          [void Function(UpdateTeamRequestBuilder)? updates]) =>
      (UpdateTeamRequestBuilder()..update(updates))._build();

  _$UpdateTeamRequest._(
      {this.name, this.alias, this.ageCategoryId, this.genderPolicy})
      : super._();
  @override
  UpdateTeamRequest rebuild(void Function(UpdateTeamRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTeamRequestBuilder toBuilder() =>
      UpdateTeamRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTeamRequest &&
        name == other.name &&
        alias == other.alias &&
        ageCategoryId == other.ageCategoryId &&
        genderPolicy == other.genderPolicy;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, alias.hashCode);
    _$hash = $jc(_$hash, ageCategoryId.hashCode);
    _$hash = $jc(_$hash, genderPolicy.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTeamRequest')
          ..add('name', name)
          ..add('alias', alias)
          ..add('ageCategoryId', ageCategoryId)
          ..add('genderPolicy', genderPolicy))
        .toString();
  }
}

class UpdateTeamRequestBuilder
    implements Builder<UpdateTeamRequest, UpdateTeamRequestBuilder> {
  _$UpdateTeamRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _alias;
  String? get alias => _$this._alias;
  set alias(String? alias) => _$this._alias = alias;

  String? _ageCategoryId;
  String? get ageCategoryId => _$this._ageCategoryId;
  set ageCategoryId(String? ageCategoryId) =>
      _$this._ageCategoryId = ageCategoryId;

  GenderPolicy? _genderPolicy;
  GenderPolicy? get genderPolicy => _$this._genderPolicy;
  set genderPolicy(GenderPolicy? genderPolicy) =>
      _$this._genderPolicy = genderPolicy;

  UpdateTeamRequestBuilder() {
    UpdateTeamRequest._defaults(this);
  }

  UpdateTeamRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _alias = $v.alias;
      _ageCategoryId = $v.ageCategoryId;
      _genderPolicy = $v.genderPolicy;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTeamRequest other) {
    _$v = other as _$UpdateTeamRequest;
  }

  @override
  void update(void Function(UpdateTeamRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTeamRequest build() => _build();

  _$UpdateTeamRequest _build() {
    final _$result = _$v ??
        _$UpdateTeamRequest._(
          name: name,
          alias: alias,
          ageCategoryId: ageCategoryId,
          genderPolicy: genderPolicy,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
