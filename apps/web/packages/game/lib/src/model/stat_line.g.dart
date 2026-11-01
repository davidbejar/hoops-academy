// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stat_line.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StatLine extends StatLine {
  @override
  final int points;
  @override
  final int fg1Made;
  @override
  final int fg1Attempted;
  @override
  final int fg2Made;
  @override
  final int fg2Attempted;
  @override
  final int fg3Made;
  @override
  final int fg3Attempted;
  @override
  final int assists;
  @override
  final int offensiveRebounds;
  @override
  final int defensiveRebounds;
  @override
  final int turnovers;
  @override
  final int steals;
  @override
  final int blocks;
  @override
  final int personalFouls;
  @override
  final int secondsPlayed;

  factory _$StatLine([void Function(StatLineBuilder)? updates]) =>
      (StatLineBuilder()..update(updates))._build();

  _$StatLine._(
      {required this.points,
      required this.fg1Made,
      required this.fg1Attempted,
      required this.fg2Made,
      required this.fg2Attempted,
      required this.fg3Made,
      required this.fg3Attempted,
      required this.assists,
      required this.offensiveRebounds,
      required this.defensiveRebounds,
      required this.turnovers,
      required this.steals,
      required this.blocks,
      required this.personalFouls,
      required this.secondsPlayed})
      : super._();
  @override
  StatLine rebuild(void Function(StatLineBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StatLineBuilder toBuilder() => StatLineBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StatLine &&
        points == other.points &&
        fg1Made == other.fg1Made &&
        fg1Attempted == other.fg1Attempted &&
        fg2Made == other.fg2Made &&
        fg2Attempted == other.fg2Attempted &&
        fg3Made == other.fg3Made &&
        fg3Attempted == other.fg3Attempted &&
        assists == other.assists &&
        offensiveRebounds == other.offensiveRebounds &&
        defensiveRebounds == other.defensiveRebounds &&
        turnovers == other.turnovers &&
        steals == other.steals &&
        blocks == other.blocks &&
        personalFouls == other.personalFouls &&
        secondsPlayed == other.secondsPlayed;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, points.hashCode);
    _$hash = $jc(_$hash, fg1Made.hashCode);
    _$hash = $jc(_$hash, fg1Attempted.hashCode);
    _$hash = $jc(_$hash, fg2Made.hashCode);
    _$hash = $jc(_$hash, fg2Attempted.hashCode);
    _$hash = $jc(_$hash, fg3Made.hashCode);
    _$hash = $jc(_$hash, fg3Attempted.hashCode);
    _$hash = $jc(_$hash, assists.hashCode);
    _$hash = $jc(_$hash, offensiveRebounds.hashCode);
    _$hash = $jc(_$hash, defensiveRebounds.hashCode);
    _$hash = $jc(_$hash, turnovers.hashCode);
    _$hash = $jc(_$hash, steals.hashCode);
    _$hash = $jc(_$hash, blocks.hashCode);
    _$hash = $jc(_$hash, personalFouls.hashCode);
    _$hash = $jc(_$hash, secondsPlayed.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'StatLine')
          ..add('points', points)
          ..add('fg1Made', fg1Made)
          ..add('fg1Attempted', fg1Attempted)
          ..add('fg2Made', fg2Made)
          ..add('fg2Attempted', fg2Attempted)
          ..add('fg3Made', fg3Made)
          ..add('fg3Attempted', fg3Attempted)
          ..add('assists', assists)
          ..add('offensiveRebounds', offensiveRebounds)
          ..add('defensiveRebounds', defensiveRebounds)
          ..add('turnovers', turnovers)
          ..add('steals', steals)
          ..add('blocks', blocks)
          ..add('personalFouls', personalFouls)
          ..add('secondsPlayed', secondsPlayed))
        .toString();
  }
}

class StatLineBuilder implements Builder<StatLine, StatLineBuilder> {
  _$StatLine? _$v;

  int? _points;
  int? get points => _$this._points;
  set points(int? points) => _$this._points = points;

  int? _fg1Made;
  int? get fg1Made => _$this._fg1Made;
  set fg1Made(int? fg1Made) => _$this._fg1Made = fg1Made;

  int? _fg1Attempted;
  int? get fg1Attempted => _$this._fg1Attempted;
  set fg1Attempted(int? fg1Attempted) => _$this._fg1Attempted = fg1Attempted;

  int? _fg2Made;
  int? get fg2Made => _$this._fg2Made;
  set fg2Made(int? fg2Made) => _$this._fg2Made = fg2Made;

  int? _fg2Attempted;
  int? get fg2Attempted => _$this._fg2Attempted;
  set fg2Attempted(int? fg2Attempted) => _$this._fg2Attempted = fg2Attempted;

  int? _fg3Made;
  int? get fg3Made => _$this._fg3Made;
  set fg3Made(int? fg3Made) => _$this._fg3Made = fg3Made;

  int? _fg3Attempted;
  int? get fg3Attempted => _$this._fg3Attempted;
  set fg3Attempted(int? fg3Attempted) => _$this._fg3Attempted = fg3Attempted;

  int? _assists;
  int? get assists => _$this._assists;
  set assists(int? assists) => _$this._assists = assists;

  int? _offensiveRebounds;
  int? get offensiveRebounds => _$this._offensiveRebounds;
  set offensiveRebounds(int? offensiveRebounds) =>
      _$this._offensiveRebounds = offensiveRebounds;

  int? _defensiveRebounds;
  int? get defensiveRebounds => _$this._defensiveRebounds;
  set defensiveRebounds(int? defensiveRebounds) =>
      _$this._defensiveRebounds = defensiveRebounds;

  int? _turnovers;
  int? get turnovers => _$this._turnovers;
  set turnovers(int? turnovers) => _$this._turnovers = turnovers;

  int? _steals;
  int? get steals => _$this._steals;
  set steals(int? steals) => _$this._steals = steals;

  int? _blocks;
  int? get blocks => _$this._blocks;
  set blocks(int? blocks) => _$this._blocks = blocks;

  int? _personalFouls;
  int? get personalFouls => _$this._personalFouls;
  set personalFouls(int? personalFouls) =>
      _$this._personalFouls = personalFouls;

  int? _secondsPlayed;
  int? get secondsPlayed => _$this._secondsPlayed;
  set secondsPlayed(int? secondsPlayed) =>
      _$this._secondsPlayed = secondsPlayed;

  StatLineBuilder() {
    StatLine._defaults(this);
  }

  StatLineBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _points = $v.points;
      _fg1Made = $v.fg1Made;
      _fg1Attempted = $v.fg1Attempted;
      _fg2Made = $v.fg2Made;
      _fg2Attempted = $v.fg2Attempted;
      _fg3Made = $v.fg3Made;
      _fg3Attempted = $v.fg3Attempted;
      _assists = $v.assists;
      _offensiveRebounds = $v.offensiveRebounds;
      _defensiveRebounds = $v.defensiveRebounds;
      _turnovers = $v.turnovers;
      _steals = $v.steals;
      _blocks = $v.blocks;
      _personalFouls = $v.personalFouls;
      _secondsPlayed = $v.secondsPlayed;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StatLine other) {
    _$v = other as _$StatLine;
  }

  @override
  void update(void Function(StatLineBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  StatLine build() => _build();

  _$StatLine _build() {
    final _$result = _$v ??
        _$StatLine._(
          points: BuiltValueNullFieldError.checkNotNull(
              points, r'StatLine', 'points'),
          fg1Made: BuiltValueNullFieldError.checkNotNull(
              fg1Made, r'StatLine', 'fg1Made'),
          fg1Attempted: BuiltValueNullFieldError.checkNotNull(
              fg1Attempted, r'StatLine', 'fg1Attempted'),
          fg2Made: BuiltValueNullFieldError.checkNotNull(
              fg2Made, r'StatLine', 'fg2Made'),
          fg2Attempted: BuiltValueNullFieldError.checkNotNull(
              fg2Attempted, r'StatLine', 'fg2Attempted'),
          fg3Made: BuiltValueNullFieldError.checkNotNull(
              fg3Made, r'StatLine', 'fg3Made'),
          fg3Attempted: BuiltValueNullFieldError.checkNotNull(
              fg3Attempted, r'StatLine', 'fg3Attempted'),
          assists: BuiltValueNullFieldError.checkNotNull(
              assists, r'StatLine', 'assists'),
          offensiveRebounds: BuiltValueNullFieldError.checkNotNull(
              offensiveRebounds, r'StatLine', 'offensiveRebounds'),
          defensiveRebounds: BuiltValueNullFieldError.checkNotNull(
              defensiveRebounds, r'StatLine', 'defensiveRebounds'),
          turnovers: BuiltValueNullFieldError.checkNotNull(
              turnovers, r'StatLine', 'turnovers'),
          steals: BuiltValueNullFieldError.checkNotNull(
              steals, r'StatLine', 'steals'),
          blocks: BuiltValueNullFieldError.checkNotNull(
              blocks, r'StatLine', 'blocks'),
          personalFouls: BuiltValueNullFieldError.checkNotNull(
              personalFouls, r'StatLine', 'personalFouls'),
          secondsPlayed: BuiltValueNullFieldError.checkNotNull(
              secondsPlayed, r'StatLine', 'secondsPlayed'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
