// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_roster_entry.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchRosterEntry extends MatchRosterEntry {
  @override
  final String playerId;
  @override
  final String displayName;
  @override
  final String? jerseyNumber;
  @override
  final bool isStarter;

  factory _$MatchRosterEntry(
          [void Function(MatchRosterEntryBuilder)? updates]) =>
      (MatchRosterEntryBuilder()..update(updates))._build();

  _$MatchRosterEntry._(
      {required this.playerId,
      required this.displayName,
      this.jerseyNumber,
      required this.isStarter})
      : super._();
  @override
  MatchRosterEntry rebuild(void Function(MatchRosterEntryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchRosterEntryBuilder toBuilder() =>
      MatchRosterEntryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchRosterEntry &&
        playerId == other.playerId &&
        displayName == other.displayName &&
        jerseyNumber == other.jerseyNumber &&
        isStarter == other.isStarter;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, isStarter.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchRosterEntry')
          ..add('playerId', playerId)
          ..add('displayName', displayName)
          ..add('jerseyNumber', jerseyNumber)
          ..add('isStarter', isStarter))
        .toString();
  }
}

class MatchRosterEntryBuilder
    implements Builder<MatchRosterEntry, MatchRosterEntryBuilder> {
  _$MatchRosterEntry? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  bool? _isStarter;
  bool? get isStarter => _$this._isStarter;
  set isStarter(bool? isStarter) => _$this._isStarter = isStarter;

  MatchRosterEntryBuilder() {
    MatchRosterEntry._defaults(this);
  }

  MatchRosterEntryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _displayName = $v.displayName;
      _jerseyNumber = $v.jerseyNumber;
      _isStarter = $v.isStarter;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchRosterEntry other) {
    _$v = other as _$MatchRosterEntry;
  }

  @override
  void update(void Function(MatchRosterEntryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchRosterEntry build() => _build();

  _$MatchRosterEntry _build() {
    final _$result = _$v ??
        _$MatchRosterEntry._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'MatchRosterEntry', 'playerId'),
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'MatchRosterEntry', 'displayName'),
          jerseyNumber: jerseyNumber,
          isStarter: BuiltValueNullFieldError.checkNotNull(
              isStarter, r'MatchRosterEntry', 'isStarter'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
