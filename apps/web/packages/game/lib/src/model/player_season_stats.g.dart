// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_season_stats.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlayerSeasonStats extends PlayerSeasonStats {
  @override
  final String playerId;
  @override
  final String seasonId;
  @override
  final int gamesPlayed;
  @override
  final int gamesStarted;
  @override
  final StatLine totals;
  @override
  final StatAverages averages;
  @override
  final BuiltList<PlayerMatchLine> matches;

  factory _$PlayerSeasonStats(
          [void Function(PlayerSeasonStatsBuilder)? updates]) =>
      (PlayerSeasonStatsBuilder()..update(updates))._build();

  _$PlayerSeasonStats._(
      {required this.playerId,
      required this.seasonId,
      required this.gamesPlayed,
      required this.gamesStarted,
      required this.totals,
      required this.averages,
      required this.matches})
      : super._();
  @override
  PlayerSeasonStats rebuild(void Function(PlayerSeasonStatsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerSeasonStatsBuilder toBuilder() =>
      PlayerSeasonStatsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerSeasonStats &&
        playerId == other.playerId &&
        seasonId == other.seasonId &&
        gamesPlayed == other.gamesPlayed &&
        gamesStarted == other.gamesStarted &&
        totals == other.totals &&
        averages == other.averages &&
        matches == other.matches;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jc(_$hash, seasonId.hashCode);
    _$hash = $jc(_$hash, gamesPlayed.hashCode);
    _$hash = $jc(_$hash, gamesStarted.hashCode);
    _$hash = $jc(_$hash, totals.hashCode);
    _$hash = $jc(_$hash, averages.hashCode);
    _$hash = $jc(_$hash, matches.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlayerSeasonStats')
          ..add('playerId', playerId)
          ..add('seasonId', seasonId)
          ..add('gamesPlayed', gamesPlayed)
          ..add('gamesStarted', gamesStarted)
          ..add('totals', totals)
          ..add('averages', averages)
          ..add('matches', matches))
        .toString();
  }
}

class PlayerSeasonStatsBuilder
    implements Builder<PlayerSeasonStats, PlayerSeasonStatsBuilder> {
  _$PlayerSeasonStats? _$v;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  String? _seasonId;
  String? get seasonId => _$this._seasonId;
  set seasonId(String? seasonId) => _$this._seasonId = seasonId;

  int? _gamesPlayed;
  int? get gamesPlayed => _$this._gamesPlayed;
  set gamesPlayed(int? gamesPlayed) => _$this._gamesPlayed = gamesPlayed;

  int? _gamesStarted;
  int? get gamesStarted => _$this._gamesStarted;
  set gamesStarted(int? gamesStarted) => _$this._gamesStarted = gamesStarted;

  StatLineBuilder? _totals;
  StatLineBuilder get totals => _$this._totals ??= StatLineBuilder();
  set totals(StatLineBuilder? totals) => _$this._totals = totals;

  StatAveragesBuilder? _averages;
  StatAveragesBuilder get averages =>
      _$this._averages ??= StatAveragesBuilder();
  set averages(StatAveragesBuilder? averages) => _$this._averages = averages;

  ListBuilder<PlayerMatchLine>? _matches;
  ListBuilder<PlayerMatchLine> get matches =>
      _$this._matches ??= ListBuilder<PlayerMatchLine>();
  set matches(ListBuilder<PlayerMatchLine>? matches) =>
      _$this._matches = matches;

  PlayerSeasonStatsBuilder() {
    PlayerSeasonStats._defaults(this);
  }

  PlayerSeasonStatsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _playerId = $v.playerId;
      _seasonId = $v.seasonId;
      _gamesPlayed = $v.gamesPlayed;
      _gamesStarted = $v.gamesStarted;
      _totals = $v.totals.toBuilder();
      _averages = $v.averages.toBuilder();
      _matches = $v.matches.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerSeasonStats other) {
    _$v = other as _$PlayerSeasonStats;
  }

  @override
  void update(void Function(PlayerSeasonStatsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlayerSeasonStats build() => _build();

  _$PlayerSeasonStats _build() {
    _$PlayerSeasonStats _$result;
    try {
      _$result = _$v ??
          _$PlayerSeasonStats._(
            playerId: BuiltValueNullFieldError.checkNotNull(
                playerId, r'PlayerSeasonStats', 'playerId'),
            seasonId: BuiltValueNullFieldError.checkNotNull(
                seasonId, r'PlayerSeasonStats', 'seasonId'),
            gamesPlayed: BuiltValueNullFieldError.checkNotNull(
                gamesPlayed, r'PlayerSeasonStats', 'gamesPlayed'),
            gamesStarted: BuiltValueNullFieldError.checkNotNull(
                gamesStarted, r'PlayerSeasonStats', 'gamesStarted'),
            totals: totals.build(),
            averages: averages.build(),
            matches: matches.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'totals';
        totals.build();
        _$failedField = 'averages';
        averages.build();
        _$failedField = 'matches';
        matches.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PlayerSeasonStats', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
