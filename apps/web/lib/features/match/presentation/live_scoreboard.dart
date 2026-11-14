import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/game_clock.dart';
import '../application/live_match_controller.dart';
import '../domain/match_event.dart';
import 'match_labels.dart';

/// The band above the tabs: both scores, the period, the game clock (staff)
/// or the match state, the staff's scoring strip (period, opponent points,
/// timeout, undo) and the notes on how this view works (cached, parent mode,
/// read only).
class LiveScoreboard extends ConsumerWidget {
  const LiveScoreboard({super.key, required this.live, required this.clock});
  final LiveMatch live;
  final GameClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final gutter = WidthClass.of(context).gutter;
    final p = live.projection;
    final staff = live.rights.canRunMatch && !live.finished;
    final period = p.live.period == 0
        ? l.matchBeforeStart
        : periodLabel(l, p.live.period, live.rules.periodCount);
    final notes = _ModeNotes(live: live);
    return DecoratedBox(
      key: const Key('scoreboard'),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          gutter,
          HoopsSpace.sm,
          gutter,
          HoopsSpace.gap,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TeamScore(
                    name: l.matchUs,
                    score: live.team.teamScore,
                    scoreKey: const Key('score-team'),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      period,
                      key: const Key('period-label'),
                      style: text.titleMedium,
                    ),
                    if (staff)
                      _ClockControl(clock: clock)
                    else
                      statusChip(l, live.match.status),
                  ],
                ),
                Expanded(
                  child: _TeamScore(
                    name: live.match.opponentName,
                    score: live.team.opponentScore,
                    scoreKey: const Key('score-opponent'),
                  ),
                ),
              ],
            ),
            if (staff) ...[
              const SizedBox(height: HoopsSpace.sm),
              _ScoringStrip(live: live, clock: clock, period: period),
            ] else if (live.rights.parentMode && !live.finished)
              Align(
                alignment: Alignment.centerRight,
                child: UndoButton(matchId: live.match.id),
              ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: HoopsSpace.gap),
              notes,
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.name,
    required this.score,
    required this.scoreKey,
  });
  final String name;
  final int score;
  final Key scoreKey;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          name,
          style: text.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text('$score', key: scoreKey, style: tabular(text.displaySmall!)),
      ],
    );
  }
}

/// Cached data, parent mode, read only: how this view behaves, as chips.
class _ModeNotes extends StatelessWidget {
  const _ModeNotes({required this.live});
  final LiveMatch live;

  bool get isNotEmpty =>
      live.fromCache || live.rights.parentMode || !live.rights.canScore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: HoopsSpace.sm,
      runSpacing: HoopsSpace.sm,
      children: [
        if (live.fromCache)
          StatusChip(
            l.matchCachedData,
            key: const Key('live-cached'),
            tone: HoopsTone.warning,
            icon: Icons.cloud_off,
          ),
        if (live.rights.parentMode)
          StatusChip(
            l.matchParentMode,
            key: const Key('parent-mode'),
            tone: HoopsTone.info,
            icon: Icons.family_restroom,
          )
        else if (!live.rights.canScore)
          StatusChip(
            l.matchReadOnly,
            key: const Key('read-only'),
            icon: Icons.visibility_outlined,
          ),
      ],
    );
  }
}

/// Period start / end, opponent points, timeout and undo in one scrolling
/// row of full-height buttons.
class _ScoringStrip extends ConsumerWidget {
  const _ScoringStrip({
    required this.live,
    required this.clock,
    required this.period,
  });
  final LiveMatch live;
  final GameClock clock;
  final String period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final ctl = ref.read(liveMatchProvider(live.match.id).notifier);
    final periodStyle = FilledButton.styleFrom(
      backgroundColor: c.accentSoft,
      foregroundColor: c.onAccentSoft,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: HoopsSpace.sm,
        children: [
          if (live.projection.live.running)
            FilledButton.icon(
              key: const Key('period-end'),
              style: periodStyle,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l.matchEndPeriod(period)),
              onPressed: () async {
                clock.pause();
                await runAction(
                  context,
                  () => ctl.endPeriod(clock: clock.remaining),
                );
              },
            )
          else
            FilledButton.icon(
              key: const Key('period-start'),
              style: periodStyle,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(
                l.matchStartPeriod(
                  periodLabel(l, live.nextPeriod, live.rules.periodCount),
                ),
              ),
              onPressed: () async {
                final seconds = live.rules.periodSeconds(live.nextPeriod);
                clock.set(seconds);
                await runAction(context, () => ctl.startPeriod(clock: seconds));
              },
            ),
          for (final points in const [1, 2, 3])
            OutlinedButton(
              key: Key('opponent-$points'),
              onPressed: () => runAction(
                context,
                () => ctl.opponentScore(points, clock: clock.remaining),
              ),
              child: Text(l.matchOpponentPoints(points)),
            ),
          IconButton.outlined(
            key: const Key('timeout-menu'),
            tooltip: l.matchTimeoutOwn,
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => _timeout(context, ctl),
          ),
          UndoButton(matchId: live.match.id, outlined: true),
        ],
      ),
    );
  }

  Future<void> _timeout(BuildContext context, LiveMatchController ctl) async {
    final l = AppLocalizations.of(context);
    final side = await showActionSheet<TimeoutSide>(
      context,
      actions: [
        SheetAction(
          icon: Icons.timer_outlined,
          label: l.matchTimeoutOwn,
          value: TimeoutSide.own,
        ),
        SheetAction(
          icon: Icons.timer_outlined,
          label: l.matchTimeoutOpponent,
          value: TimeoutSide.opponent,
        ),
      ],
    );
    if (side == null || !context.mounted) return;
    clock.pause();
    await runAction(context, () => ctl.timeout(side, clock: clock.remaining));
  }
}

/// Voids the caller's last event; says when there was nothing to undo.
class UndoButton extends ConsumerWidget {
  const UndoButton({super.key, required this.matchId, this.outlined = false});
  final String matchId;
  final bool outlined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Future<void> undo() async {
      final messenger = ScaffoldMessenger.of(context);
      var done = false;
      final ok = await runAction(
        context,
        () async =>
            done = await ref.read(liveMatchProvider(matchId).notifier).undo(),
      );
      if (ok)
        messenger.showSnackBar(
          SnackBar(content: Text(done ? l.matchUndone : l.matchNothingToUndo)),
        );
    }

    const key = Key('undo');
    const icon = Icon(Icons.undo);
    return outlined
        ? IconButton.outlined(
            key: key,
            tooltip: l.matchUndo,
            icon: icon,
            onPressed: undo,
          )
        : IconButton(
            key: key,
            tooltip: l.matchUndo,
            icon: icon,
            onPressed: undo,
          );
  }
}

/// Minus / plus ten seconds around the clock, and start / pause.
class _ClockControl extends StatelessWidget {
  const _ClockControl({required this.clock});
  final GameClock clock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) => Row(
        key: const Key('game-clock'),
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('clock-minus'),
            tooltip: l.matchClockMinus,
            icon: const Icon(Icons.remove),
            onPressed: () => clock.adjust(-10),
          ),
          Text(
            formatClock(clock.remaining),
            key: const Key('clock-value'),
            style: tabular(text.headlineSmall!),
          ),
          IconButton(
            key: const Key('clock-plus'),
            tooltip: l.matchClockPlus,
            icon: const Icon(Icons.add),
            onPressed: () => clock.adjust(10),
          ),
          IconButton.filled(
            key: const Key('clock-toggle'),
            tooltip: clock.running ? l.matchClockPause : l.matchClockStart,
            icon: Icon(clock.running ? Icons.pause : Icons.play_arrow),
            onPressed: clock.toggle,
          ),
        ],
      ),
    );
  }
}
