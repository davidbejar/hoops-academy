// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Player extends Player {
  @override
  final String id;
  @override
  final String personId;
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final String displayName;
  @override
  final Date birthDate;
  @override
  final Gender gender;
  @override
  final PlayerStatus status;
  @override
  final AgeCategory? naturalCategory;
  @override
  final BuiltList<PlayerTeamAssignment> teams;
  @override
  final DateTime createdAt;
  @override
  final String? preferredJerseyNumber;

  factory _$Player([void Function(PlayerBuilder)? updates]) =>
      (PlayerBuilder()..update(updates))._build();

  _$Player._(
      {required this.id,
      required this.personId,
      required this.givenName,
      required this.familyName,
      required this.displayName,
      required this.birthDate,
      required this.gender,
      required this.status,
      this.naturalCategory,
      required this.teams,
      required this.createdAt,
      this.preferredJerseyNumber})
      : super._();
  @override
  Player rebuild(void Function(PlayerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerBuilder toBuilder() => PlayerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Player &&
        id == other.id &&
        personId == other.personId &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        displayName == other.displayName &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        status == other.status &&
        naturalCategory == other.naturalCategory &&
        teams == other.teams &&
        createdAt == other.createdAt &&
        preferredJerseyNumber == other.preferredJerseyNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, personId.hashCode);
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, birthDate.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, naturalCategory.hashCode);
    _$hash = $jc(_$hash, teams.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, preferredJerseyNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Player')
          ..add('id', id)
          ..add('personId', personId)
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('displayName', displayName)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('status', status)
          ..add('naturalCategory', naturalCategory)
          ..add('teams', teams)
          ..add('createdAt', createdAt)
          ..add('preferredJerseyNumber', preferredJerseyNumber))
        .toString();
  }
}

class PlayerBuilder implements Builder<Player, PlayerBuilder> {
  _$Player? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _personId;
  String? get personId => _$this._personId;
  set personId(String? personId) => _$this._personId = personId;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  Date? _birthDate;
  Date? get birthDate => _$this._birthDate;
  set birthDate(Date? birthDate) => _$this._birthDate = birthDate;

  Gender? _gender;
  Gender? get gender => _$this._gender;
  set gender(Gender? gender) => _$this._gender = gender;

  PlayerStatus? _status;
  PlayerStatus? get status => _$this._status;
  set status(PlayerStatus? status) => _$this._status = status;

  AgeCategoryBuilder? _naturalCategory;
  AgeCategoryBuilder get naturalCategory =>
      _$this._naturalCategory ??= AgeCategoryBuilder();
  set naturalCategory(AgeCategoryBuilder? naturalCategory) =>
      _$this._naturalCategory = naturalCategory;

  ListBuilder<PlayerTeamAssignment>? _teams;
  ListBuilder<PlayerTeamAssignment> get teams =>
      _$this._teams ??= ListBuilder<PlayerTeamAssignment>();
  set teams(ListBuilder<PlayerTeamAssignment>? teams) => _$this._teams = teams;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _preferredJerseyNumber;
  String? get preferredJerseyNumber => _$this._preferredJerseyNumber;
  set preferredJerseyNumber(String? preferredJerseyNumber) =>
      _$this._preferredJerseyNumber = preferredJerseyNumber;

  PlayerBuilder() {
    Player._defaults(this);
  }

  PlayerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _personId = $v.personId;
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _displayName = $v.displayName;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _status = $v.status;
      _naturalCategory = $v.naturalCategory?.toBuilder();
      _teams = $v.teams.toBuilder();
      _createdAt = $v.createdAt;
      _preferredJerseyNumber = $v.preferredJerseyNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Player other) {
    _$v = other as _$Player;
  }

  @override
  void update(void Function(PlayerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Player build() => _build();

  _$Player _build() {
    _$Player _$result;
    try {
      _$result = _$v ??
          _$Player._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Player', 'id'),
            personId: BuiltValueNullFieldError.checkNotNull(
                personId, r'Player', 'personId'),
            givenName: BuiltValueNullFieldError.checkNotNull(
                givenName, r'Player', 'givenName'),
            familyName: BuiltValueNullFieldError.checkNotNull(
                familyName, r'Player', 'familyName'),
            displayName: BuiltValueNullFieldError.checkNotNull(
                displayName, r'Player', 'displayName'),
            birthDate: BuiltValueNullFieldError.checkNotNull(
                birthDate, r'Player', 'birthDate'),
            gender: BuiltValueNullFieldError.checkNotNull(
                gender, r'Player', 'gender'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'Player', 'status'),
            naturalCategory: _naturalCategory?.build(),
            teams: teams.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'Player', 'createdAt'),
            preferredJerseyNumber: preferredJerseyNumber,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'naturalCategory';
        _naturalCategory?.build();
        _$failedField = 'teams';
        teams.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Player', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
