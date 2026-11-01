// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roster_player.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RosterPlayer extends RosterPlayer {
  @override
  final String playerId;
  @override
  final String displayName;
  @override
  final String? jerseyNumber;
  @override
  final Date birthDate;
  @override
  final Gender gender;
  @override
  final PlayerStatus status;

  factory _$RosterPlayer([void Function(RosterPlayerBuilder)? updates]) =>
      (RosterPlayerBuilder()..update(updates))._build();

  _$RosterPlayer._(
      {required this.playerId,
      required this.displayName,
      this.jerseyNumber,
      required this.birthDate,
      required this.gender,
      required this.status})
      : super._();
  @override
  RosterPlayer rebuild(void Function(RosterPlayerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RosterPlayerBuilder toBuilder() => RosterPlayerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RosterPlayer &&
        playerId == other.playerId &&
        displayName == other.displayName &&
        jerseyNumber == other.jerseyNumber &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, birthDate.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RosterPlayer')
          ..add('playerId', playerId)
          ..add('displayName', displayName)
          ..add('jerseyNumber', jerseyNumber)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('status', status))
        .toString();
  }
}

class RosterPlayerBuilder
    implements Builder<RosterPlayer, RosterPlayerBuilder> {
  _$RosterPlayer? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  Date? _birthDate;
  Date? get birthDate => _$this._birthDate;
  set birthDate(Date? birthDate) => _$this._birthDate = birthDate;

  Gender? _gender;
  Gender? get gender => _$this._gender;
  set gender(Gender? gender) => _$this._gender = gender;

  PlayerStatus? _status;
  PlayerStatus? get status => _$this._status;
  set status(PlayerStatus? status) => _$this._status = status;

  RosterPlayerBuilder() {
    RosterPlayer._defaults(this);
  }

  RosterPlayerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _displayName = $v.displayName;
      _jerseyNumber = $v.jerseyNumber;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RosterPlayer other) {
    _$v = other as _$RosterPlayer;
  }

  @override
  void update(void Function(RosterPlayerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RosterPlayer build() => _build();

  _$RosterPlayer _build() {
    final _$result = _$v ??
        _$RosterPlayer._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'RosterPlayer', 'playerId'),
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'RosterPlayer', 'displayName'),
          jerseyNumber: jerseyNumber,
          birthDate: BuiltValueNullFieldError.checkNotNull(
              birthDate, r'RosterPlayer', 'birthDate'),
          gender: BuiltValueNullFieldError.checkNotNull(
              gender, r'RosterPlayer', 'gender'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'RosterPlayer', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
