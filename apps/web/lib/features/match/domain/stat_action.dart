import 'match_event.dart';

/// The buttons of the player action sheet, each one stat event.
enum StatAction {
  twoMade('2pt-made'),
  twoMissed('2pt-missed'),
  threeMade('3pt-made'),
  threeMissed('3pt-missed'),
  ftMade('ft-made'),
  ftMissed('ft-missed'),
  assist('ast'),
  offensiveRebound('oreb'),
  defensiveRebound('dreb'),
  steal('stl'),
  block('blk'),
  turnover('tov'),
  foulPersonal('foul-p'),
  foulTechnical('foul-t'),
  foulUnsportsmanlike('foul-u');

  const StatAction(this.code);

  /// Stable id for widget keys.
  final String code;

  PlayerStat build(EventMeta meta, String playerId) => switch (this) {
    twoMade => Shot(meta, playerId: playerId, points: 2, made: true),
    twoMissed => Shot(meta, playerId: playerId, points: 2, made: false),
    threeMade => Shot(meta, playerId: playerId, points: 3, made: true),
    threeMissed => Shot(meta, playerId: playerId, points: 3, made: false),
    ftMade => Shot(meta, playerId: playerId, points: 1, made: true),
    ftMissed => Shot(meta, playerId: playerId, points: 1, made: false),
    assist => Assist(meta, playerId: playerId),
    offensiveRebound => Rebound(meta, playerId: playerId, kind: ReboundKind.offensive),
    defensiveRebound => Rebound(meta, playerId: playerId, kind: ReboundKind.defensive),
    steal => Steal(meta, playerId: playerId),
    block => Block(meta, playerId: playerId),
    turnover => Turnover(meta, playerId: playerId),
    foulPersonal => Foul(meta, playerId: playerId, kind: FoulKind.personal),
    foulTechnical => Foul(meta, playerId: playerId, kind: FoulKind.technical),
    foulUnsportsmanlike => Foul(meta, playerId: playerId, kind: FoulKind.unsportsmanlike),
  };
}
