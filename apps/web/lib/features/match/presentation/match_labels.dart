import 'package:flutter/material.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/live_match_controller.dart';
import '../domain/match_event.dart';
import '../domain/pending_event.dart';
import '../domain/stat_action.dart';

String periodLabel(AppLocalizations l, int period, int periodCount) =>
    period > periodCount
    ? l.matchOvertimeShort(period - periodCount)
    : l.matchPeriodShort(period);

String statusLabel(AppLocalizations l, gen.MatchStatus s) => switch (s) {
  gen.MatchStatus.LIVE => l.matchStatusLive,
  gen.MatchStatus.FINISHED => l.matchStatusFinished,
  gen.MatchStatus.CANCELLED => l.matchStatusCancelled,
  _ => l.matchStatusScheduled,
};

Widget statusChip(AppLocalizations l, gen.MatchStatus s) => InfoChip(
  statusLabel(l, s),
  key: Key('status-${s.name}'),
  tone: switch (s) {
    gen.MatchStatus.LIVE => ChipTone.warn,
    gen.MatchStatus.FINISHED => ChipTone.good,
    gen.MatchStatus.CANCELLED => ChipTone.bad,
    _ => ChipTone.neutral,
  },
  icon: s == gen.MatchStatus.LIVE ? Icons.circle : null,
);

String actionLabel(AppLocalizations l, StatAction a) => switch (a) {
  StatAction.twoMade => l.matchAction2ptMade,
  StatAction.twoMissed => l.matchAction2ptMissed,
  StatAction.threeMade => l.matchAction3ptMade,
  StatAction.threeMissed => l.matchAction3ptMissed,
  StatAction.ftMade => l.matchActionFtMade,
  StatAction.ftMissed => l.matchActionFtMissed,
  StatAction.assist => l.matchActionAssist,
  StatAction.offensiveRebound => l.matchActionOreb,
  StatAction.defensiveRebound => l.matchActionDreb,
  StatAction.steal => l.matchActionSteal,
  StatAction.block => l.matchActionBlock,
  StatAction.turnover => l.matchActionTurnover,
  StatAction.foulPersonal => l.matchActionFoulPersonal,
  StatAction.foulTechnical => l.matchActionFoulTechnical,
  StatAction.foulUnsportsmanlike => l.matchActionFoulUnsportsmanlike,
};

StatAction? actionOf(MatchEvent e) => switch (e) {
  Shot(points: 2, made: true) => StatAction.twoMade,
  Shot(points: 2, made: false) => StatAction.twoMissed,
  Shot(points: 3, made: true) => StatAction.threeMade,
  Shot(points: 3, made: false) => StatAction.threeMissed,
  Shot(made: true) => StatAction.ftMade,
  Shot() => StatAction.ftMissed,
  Assist() => StatAction.assist,
  Rebound(kind: ReboundKind.offensive) => StatAction.offensiveRebound,
  Rebound() => StatAction.defensiveRebound,
  Steal() => StatAction.steal,
  Block() => StatAction.block,
  Turnover() => StatAction.turnover,
  Foul(kind: FoulKind.personal) => StatAction.foulPersonal,
  Foul(kind: FoulKind.technical) => StatAction.foulTechnical,
  Foul() => StatAction.foulUnsportsmanlike,
  _ => null,
};

/// One line describing an event in the log.
String describeEvent(
  AppLocalizations l,
  LiveMatch m,
  MatchEvent e, {
  bool nested = false,
}) {
  String name(String? id) => m.player(id)?.displayName ?? id ?? '?';
  String period() => periodLabel(l, e.meta.period, m.rules.periodCount);
  final action = actionOf(e);
  if (action != null)
    return l.matchRecorded(actionLabel(l, action), name(e.playerId));
  return switch (e) {
    PeriodStart() => l.matchEvPeriodStart(period()),
    PeriodEnd() => l.matchEvPeriodEnd(period()),
    SubIn() => l.matchEvSubIn(name(e.playerId)),
    SubOut() => l.matchEvSubOut(name(e.playerId)),
    OpponentScore(:final points) => l.matchOpponentPoints(points),
    Timeout(:final side) =>
      side == TimeoutSide.own ? l.matchTimeoutOwn : l.matchTimeoutOpponent,
    VoidEvent(:final target) => () {
      final t = nested
          ? null
          : m.log.where((x) => x.event.id == target).firstOrNull;
      return t == null
          ? l.matchEvVoidUnknown
          : l.matchEvVoid(describeEvent(l, m, t.event, nested: true));
    }(),
    Note(:final text) => l.matchEvNote(text),
    _ => e.type.wire,
  };
}

String reasonLabel(AppLocalizations l, String? reason) => switch (reason) {
  'SCHEMA_INVALID' => l.matchReasonSchema,
  'NOT_AUTHORIZED' => l.matchReasonNotAuthorized,
  'MATCH_CANCELLED' => l.matchReasonCancelled,
  'CLIENT_SEQ_CONFLICT' => l.matchReasonSeqConflict,
  _ => l.matchReasonOther,
};

String syncLabel(AppLocalizations l, LogEntry e) => switch (e.status) {
  EventStatus.pending => l.matchSyncPending,
  EventStatus.sent => l.matchSyncSent,
  EventStatus.rejected => l.matchSyncRejected(reasonLabel(l, e.rejectReason)),
  _ =>
    e.recordedBy != null && !e.mine
        ? l.matchRecordedBy(e.recordedBy!)
        : l.matchSyncDone,
};
