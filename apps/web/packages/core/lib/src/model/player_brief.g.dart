// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_brief.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerBrief extends PlayerBrief {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final Date birthDate;
  @override
  final Gender gender;
  @override
  final PlayerStatus status;

  factory _$PlayerBrief([void Function(PlayerBriefBuilder)? updates]) =>
      (PlayerBriefBuilder()..update(updates))._build();

  _$PlayerBrief._(
      {required this.id,
      required this.displayName,
      required this.birthDate,
      required this.gender,
      required this.status})
      : super._();
  @override
  PlayerBrief rebuild(void Function(PlayerBriefBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerBriefBuilder toBuilder() => PlayerBriefBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerBrief &&
        id == other.id &&
        displayName == other.displayName &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, birthDate.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerBrief')
          ..add('id', id)
          ..add('displayName', displayName)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('status', status))
        .toString();
  }
}

class PlayerBriefBuilder implements Builder<PlayerBrief, PlayerBriefBuilder> {
  _$PlayerBrief? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

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

  PlayerBriefBuilder() {
    PlayerBrief._defaults(this);
  }

  PlayerBriefBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _displayName = $v.displayName;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerBrief other) {
    _$v = other as _$PlayerBrief;
  }

  @override
  void update(void Function(PlayerBriefBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerBrief build() => _build();

  _$PlayerBrief _build() {
    final _$result = _$v ??
        _$PlayerBrief._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PlayerBrief', 'id'),
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'PlayerBrief', 'displayName'),
          birthDate: BuiltValueNullFieldError.checkNotNull(
              birthDate, r'PlayerBrief', 'birthDate'),
          gender: BuiltValueNullFieldError.checkNotNull(
              gender, r'PlayerBrief', 'gender'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PlayerBrief', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
