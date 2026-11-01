// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_match_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerMatchStats extends PlayerMatchStats {
  @override
  final String playerId;
  @override
  final String displayName;
  @override
  final String? jerseyNumber;
  @override
  final bool wasStarter;
  @override
  final StatLine stats;
  @override
  final BuiltList<ProjectionWarning> warnings;

  factory _$PlayerMatchStats(
          [void Function(PlayerMatchStatsBuilder)? updates]) =>
      (PlayerMatchStatsBuilder()..update(updates))._build();

  _$PlayerMatchStats._(
      {required this.playerId,
      required this.displayName,
      this.jerseyNumber,
      required this.wasStarter,
      required this.stats,
      required this.warnings})
      : super._();
  @override
  PlayerMatchStats rebuild(void Function(PlayerMatchStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerMatchStatsBuilder toBuilder() =>
      PlayerMatchStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerMatchStats &&
        playerId == other.playerId &&
        displayName == other.displayName &&
        jerseyNumber == other.jerseyNumber &&
        wasStarter == other.wasStarter &&
        stats == other.stats &&
        warnings == other.warnings;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, wasStarter.hashCode);
    _$hash = $jc(_$hash, stats.hashCode);
    _$hash = $jc(_$hash, warnings.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerMatchStats')
          ..add('playerId', playerId)
          ..add('displayName', displayName)
          ..add('jerseyNumber', jerseyNumber)
          ..add('wasStarter', wasStarter)
          ..add('stats', stats)
          ..add('warnings', warnings))
        .toString();
  }
}

class PlayerMatchStatsBuilder
    implements Builder<PlayerMatchStats, PlayerMatchStatsBuilder> {
  _$PlayerMatchStats? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  bool? _wasStarter;
  bool? get wasStarter => _$this._wasStarter;
  set wasStarter(bool? wasStarter) => _$this._wasStarter = wasStarter;

  StatLineBuilder? _stats;
  StatLineBuilder get stats => _$this._stats ??= StatLineBuilder();
  set stats(StatLineBuilder? stats) => _$this._stats = stats;

  ListBuilder<ProjectionWarning>? _warnings;
  ListBuilder<ProjectionWarning> get warnings =>
      _$this._warnings ??= ListBuilder<ProjectionWarning>();
  set warnings(ListBuilder<ProjectionWarning>? warnings) =>
      _$this._warnings = warnings;

  PlayerMatchStatsBuilder() {
    PlayerMatchStats._defaults(this);
  }

  PlayerMatchStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _displayName = $v.displayName;
      _jerseyNumber = $v.jerseyNumber;
      _wasStarter = $v.wasStarter;
      _stats = $v.stats.toBuilder();
      _warnings = $v.warnings.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerMatchStats other) {
    _$v = other as _$PlayerMatchStats;
  }

  @override
  void update(void Function(PlayerMatchStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerMatchStats build() => _build();

  _$PlayerMatchStats _build() {
    _$PlayerMatchStats _$result;
    try {
      _$result = _$v ??
          _$PlayerMatchStats._(
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlayerMatchStats', 'playerId'),
            displayName: BuiltValueNullFieldError.checkNotNull(
                displayName, r'PlayerMatchStats', 'displayName'),
            jerseyNumber: jerseyNumber,
            wasStarter: BuiltValueNullFieldError.checkNotNull(
                wasStarter, r'PlayerMatchStats', 'wasStarter'),
            stats: stats.build(),
            warnings: warnings.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'stats';
        stats.build();
        _$failedField = 'warnings';
        warnings.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerMatchStats', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
