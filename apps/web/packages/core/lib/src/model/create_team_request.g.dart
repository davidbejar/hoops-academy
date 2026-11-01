// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_team_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateTeamRequest extends CreateTeamRequest {
  @override
  final String seasonId;
  @override
  final String name;
  @override
  final String? alias;
  @override
  final String ageCategoryId;
  @override
  final GenderPolicy genderPolicy;

  factory _$CreateTeamRequest(
          [void Function(CreateTeamRequestBuilder)? updates]) =>
      (CreateTeamRequestBuilder()..update(updates))._build();

  _$CreateTeamRequest._(
      {required this.seasonId,
      required this.name,
      this.alias,
      required this.ageCategoryId,
      required this.genderPolicy})
      : super._();
  @override
  CreateTeamRequest rebuild(void Function(CreateTeamRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTeamRequestBuilder toBuilder() =>
      CreateTeamRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTeamRequest &&
        seasonId == other.seasonId &&
        name == other.name &&
        alias == other.alias &&
        ageCategoryId == other.ageCategoryId &&
        genderPolicy == other.genderPolicy;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, alias.hashCode);
    _$hash = $jc(_$hash, ageCategoryId.hashCode);
    _$hash = $jc(_$hash, genderPolicy.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTeamRequest')
          ..add('seasonId', seasonId)
          ..add('name', name)
          ..add('alias', alias)
          ..add('ageCategoryId', ageCategoryId)
          ..add('genderPolicy', genderPolicy))
        .toString();
  }
}

class CreateTeamRequestBuilder
    implements Builder<CreateTeamRequest, CreateTeamRequestBuilder> {
  _$CreateTeamRequest? _$v;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

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

  CreateTeamRequestBuilder() {
    CreateTeamRequest._defaults(this);
  }

  CreateTeamRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _seasonId = $v.seasonId;
      _name = $v.name;
      _alias = $v.alias;
      _ageCategoryId = $v.ageCategoryId;
      _genderPolicy = $v.genderPolicy;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTeamRequest other) {
    _$v = other as _$CreateTeamRequest;
  }

  @override
  void update(void Function(CreateTeamRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTeamRequest build() => _build();

  _$CreateTeamRequest _build() {
    final _$result = _$v ??
        _$CreateTeamRequest._(
          seasonId: BuiltValueNullFieldError.checkNotNull(
              seasonId, r'CreateTeamRequest', 'seasonId'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'CreateTeamRequest', 'name'),
          alias: alias,
          ageCategoryId: BuiltValueNullFieldError.checkNotNull(
              ageCategoryId, r'CreateTeamRequest', 'ageCategoryId'),
          genderPolicy: BuiltValueNullFieldError.checkNotNull(
              genderPolicy, r'CreateTeamRequest', 'genderPolicy'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
