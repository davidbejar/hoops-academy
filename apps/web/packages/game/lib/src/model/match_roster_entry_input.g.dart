// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_roster_entry_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MatchRosterEntryInput extends MatchRosterEntryInput {
  @override
  final String playerId;
  @override
  final String? jerseyNumber;
  @override
  final bool isStarter;

  factory _$MatchRosterEntryInput(
          [void Function(MatchRosterEntryInputBuilder)? updates]) =>
      (MatchRosterEntryInputBuilder()..update(updates))._build();

  _$MatchRosterEntryInput._(
      {required this.playerId, this.jerseyNumber, required this.isStarter})
      : super._();
  @override
  MatchRosterEntryInput rebuild(
          void Function(MatchRosterEntryInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MatchRosterEntryInputBuilder toBuilder() =>
      MatchRosterEntryInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MatchRosterEntryInput &&
        playerId == other.playerId &&
        jerseyNumber == other.jerseyNumber &&
        isStarter == other.isStarter;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, isStarter.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MatchRosterEntryInput')
          ..add('playerId', playerId)
          ..add('jerseyNumber', jerseyNumber)
          ..add('isStarter', isStarter))
        .toString();
  }
}

class MatchRosterEntryInputBuilder
    implements Builder<MatchRosterEntryInput, MatchRosterEntryInputBuilder> {
  _$MatchRosterEntryInput? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  bool? _isStarter;
  bool? get isStarter => _$this._isStarter;
  set isStarter(bool? isStarter) => _$this._isStarter = isStarter;

  MatchRosterEntryInputBuilder() {
    MatchRosterEntryInput._defaults(this);
  }

  MatchRosterEntryInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _jerseyNumber = $v.jerseyNumber;
      _isStarter = $v.isStarter;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MatchRosterEntryInput other) {
    _$v = other as _$MatchRosterEntryInput;
  }

  @override
  void update(void Function(MatchRosterEntryInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MatchRosterEntryInput build() => _build();

  _$MatchRosterEntryInput _build() {
    final _$result = _$v ??
        _$MatchRosterEntryInput._(
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'MatchRosterEntryInput', 'playerId'),
          jerseyNumber: jerseyNumber,
          isStarter: BuiltValueNullFieldError.checkNotNull(
              isStarter, r'MatchRosterEntryInput', 'isStarter'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
