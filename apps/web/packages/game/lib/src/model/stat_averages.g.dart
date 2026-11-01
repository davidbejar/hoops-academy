// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stat_averages.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StatAverages extends StatAverages {
  @override
  final double points;
  @override
  final double assists;
  @override
  final double rebounds;
  @override
  final double steals;
  @override
  final double blocks;
  @override
  final double turnovers;
  @override
  final double personalFouls;
  @override
  final double minutesPlayed;

  factory _$StatAverages([void Function(StatAveragesBuilder)? updates]) =>
      (StatAveragesBuilder()..update(updates))._build();

  _$StatAverages._(
      {required this.points,
      required this.assists,
      required this.rebounds,
      required this.steals,
      required this.blocks,
      required this.turnovers,
      required this.personalFouls,
      required this.minutesPlayed})
      : super._();
  @override
  StatAverages rebuild(void Function(StatAveragesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StatAveragesBuilder toBuilder() => StatAveragesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StatAverages &&
        points == other.points &&
        assists == other.assists &&
        rebounds == other.rebounds &&
        steals == other.steals &&
        blocks == other.blocks &&
        turnovers == other.turnovers &&
        personalFouls == other.personalFouls &&
        minutesPlayed == other.minutesPlayed;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, points.hashCode);
    _$hash = $jc(_$hash, assists.hashCode);
    _$hash = $jc(_$hash, rebounds.hashCode);
    _$hash = $jc(_$hash, steals.hashCode);
    _$hash = $jc(_$hash, blocks.hashCode);
    _$hash = $jc(_$hash, turnovers.hashCode);
    _$hash = $jc(_$hash, personalFouls.hashCode);
    _$hash = $jc(_$hash, minutesPlayed.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'StatAverages')
          ..add('points', points)
          ..add('assists', assists)
          ..add('rebounds', rebounds)
          ..add('steals', steals)
          ..add('blocks', blocks)
          ..add('turnovers', turnovers)
          ..add('personalFouls', personalFouls)
          ..add('minutesPlayed', minutesPlayed))
        .toString();
  }
}

class StatAveragesBuilder
    implements Builder<StatAverages, StatAveragesBuilder> {
  _$StatAverages? _$v;

  double? _points;
  double? get points => _$this._points;
  set points(double? points) => _$this._points = points;

  double? _assists;
  double? get assists => _$this._assists;
  set assists(double? assists) => _$this._assists = assists;

  double? _rebounds;
  double? get rebounds => _$this._rebounds;
  set rebounds(double? rebounds) => _$this._rebounds = rebounds;

  double? _steals;
  double? get steals => _$this._steals;
  set steals(double? steals) => _$this._steals = steals;

  double? _blocks;
  double? get blocks => _$this._blocks;
  set blocks(double? blocks) => _$this._blocks = blocks;

  double? _turnovers;
  double? get turnovers => _$this._turnovers;
  set turnovers(double? turnovers) => _$this._turnovers = turnovers;

  double? _personalFouls;
  double? get personalFouls => _$this._personalFouls;
  set personalFouls(double? personalFouls) =>
      _$this._personalFouls = personalFouls;

  double? _minutesPlayed;
  double? get minutesPlayed => _$this._minutesPlayed;
  set minutesPlayed(double? minutesPlayed) =>
      _$this._minutesPlayed = minutesPlayed;

  StatAveragesBuilder() {
    StatAverages._defaults(this);
  }

  StatAveragesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _points = $v.points;
      _assists = $v.assists;
      _rebounds = $v.rebounds;
      _steals = $v.steals;
      _blocks = $v.blocks;
      _turnovers = $v.turnovers;
      _personalFouls = $v.personalFouls;
      _minutesPlayed = $v.minutesPlayed;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StatAverages other) {
    _$v = other as _$StatAverages;
  }

  @override
  void update(void Function(StatAveragesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  StatAverages build() => _build();

  _$StatAverages _build() {
    final _$result = _$v ??
        _$StatAverages._(
          points: BuiltValueNullFieldError.checkNotNull(
              points, r'StatAverages', 'points'),
          assists: BuiltValueNullFieldError.checkNotNull(
              assists, r'StatAverages', 'assists'),
          rebounds: BuiltValueNullFieldError.checkNotNull(
              rebounds, r'StatAverages', 'rebounds'),
          steals: BuiltValueNullFieldError.checkNotNull(
              steals, r'StatAverages', 'steals'),
          blocks: BuiltValueNullFieldError.checkNotNull(
              blocks, r'StatAverages', 'blocks'),
          turnovers: BuiltValueNullFieldError.checkNotNull(
              turnovers, r'StatAverages', 'turnovers'),
          personalFouls: BuiltValueNullFieldError.checkNotNull(
              personalFouls, r'StatAverages', 'personalFouls'),
          minutesPlayed: BuiltValueNullFieldError.checkNotNull(
              minutesPlayed, r'StatAverages', 'minutesPlayed'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
