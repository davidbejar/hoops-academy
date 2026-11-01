// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Team extends Team {
  @override
  final String id;
  @override
  final String seasonId;
  @override
  final String name;
  @override
  final String? alias;
  @override
  final AgeCategory ageCategory;
  @override
  final GenderPolicy genderPolicy;
  @override
  final int playerCount;

  factory _$Team([void Function(TeamBuilder)? updates]) =>
      (TeamBuilder()..update(updates))._build();

  _$Team._(
      {required this.id,
      required this.seasonId,
      required this.name,
      this.alias,
      required this.ageCategory,
      required this.genderPolicy,
      required this.playerCount})
      : super._();
  @override
  Team rebuild(void Function(TeamBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamBuilder toBuilder() => TeamBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Team &&
        id == other.id &&
        seasonId == other.seasonId &&
        name == other.name &&
        alias == other.alias &&
        ageCategory == other.ageCategory &&
        genderPolicy == other.genderPolicy &&
        playerCount == other.playerCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, alias.hashCode);
    _$hash = $jc(_$hash, ageCategory.hashCode);
    _$hash = $jc(_$hash, genderPolicy.hashCode);
    _$hash = $jc(_$hash, playerCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Team')
          ..add('id', id)
          ..add('seasonId', seasonId)
          ..add('name', name)
          ..add('alias', alias)
          ..add('ageCategory', ageCategory)
          ..add('genderPolicy', genderPolicy)
          ..add('playerCount', playerCount))
        .toString();
  }
}

class TeamBuilder implements Builder<Team, TeamBuilder> {
  _$Team? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _alias;
  String? get alias => _$this._alias;
  set alias(String? alias) => _$this._alias = alias;

  AgeCategoryBuilder? _ageCategory;
  AgeCategoryBuilder get ageCategory =>
      _$this._ageCategory ??= AgeCategoryBuilder();
  set ageCategory(AgeCategoryBuilder? ageCategory) =>
      _$this._ageCategory = ageCategory;

  GenderPolicy? _genderPolicy;
  GenderPolicy? get genderPolicy => _$this._genderPolicy;
  set genderPolicy(GenderPolicy? genderPolicy) =>
      _$this._genderPolicy = genderPolicy;

  int? _playerCount;
  int? get playerCount => _$this._playerCount;
  set playerCount(int? playerCount) => _$this._playerCount = playerCount;

  TeamBuilder() {
    Team._defaults(this);
  }

  TeamBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _seasonId = $v.seasonId;
      _name = $v.name;
      _alias = $v.alias;
      _ageCategory = $v.ageCategory.toBuilder();
      _genderPolicy = $v.genderPolicy;
      _playerCount = $v.playerCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Team other) {
    _$v = other as _$Team;
  }

  @override
  void update(void Function(TeamBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Team build() => _build();

  _$Team _build() {
    _$Team _$result;
    try {
      _$result = _$v ??
          _$Team._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Team', 'id'),
            seasonId: BuiltValueNullFieldError.checkNotNull(
                seasonId, r'Team', 'seasonId'),
            name: BuiltValueNullFieldError.checkNotNull(name, r'Team', 'name'),
            alias: alias,
            ageCategory: ageCategory.build(),
            genderPolicy: BuiltValueNullFieldError.checkNotNull(
                genderPolicy, r'Team', 'genderPolicy'),
            playerCount: BuiltValueNullFieldError.checkNotNull(
                playerCount, r'Team', 'playerCount'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ageCategory';
        ageCategory.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Team', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
