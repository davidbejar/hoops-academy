import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../app/theme.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/game_clock.dart';
import '../application/live_match_controller.dart';
import '../application/match_providers.dart';
import '../domain/match_event.dart';
import '../domain/pending_event.dart';
import '../domain/projector/projector.dart';
import '../domain/stat_action.dart';
import 'box_score_view.dart';
import 'match_labels.dart';
import 'sync_banner.dart';

/// Live scoring (staff), restricted scoring (PARENT), read-only view
/// (others) and, once FINISHED, the final box score. Works offline once the
/// match and its roster were loaded.
class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  final _clock = GameClock();
  bool _clockReady = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _initClock(LiveMatch m) {
    if (_clockReady) return;
    _clockReady = true;
    final live = m.projection.live;
    _clock.set(live.running ? live.clock : m.rules.periodSeconds(m.nextPeriod));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncTriggersProvider);
    final l = AppLocalizations.of(context);
    final value = ref.watch(liveMatchProvider(widget.matchId));
    final m = value.value;
    if (m != null) _initClock(m);
    return SubPage(
      title: m == null ? l.navMatches : l.matchVs(m.match.opponentName),
      parentPath: '/matches',
      actions: [if (m != null && m.rights.canRunMatch) _StaffMenu(live: m)],
      child: AsyncBody<LiveMatch>(
        value: value,
        onRetry: () => ref.invalidate(liveMatchProvider(widget.matchId)),
        builder: (context, m) => m.roster.isEmpty ? _NoRoster(live: m) : _LiveBody(live: m, clock: _clock),
      ),
    );
  }
}

class _NoRoster extends StatelessWidget {
  const _NoRoster({required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyView(message: l.matchNoRoster),
          if (live.rights.canRunMatch)
            FilledButton.icon(
              key: const Key('open-setup'),
              onPressed: () => context.go('/matches/${live.match.id}/setup'),
              icon: const Icon(Icons.groups),
              label: Text(l.matchSetupAction),
            ),
        ],
      ),
    );
  }
}

class _StaffMenu extends ConsumerWidget {
  const _StaffMenu({required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ctl = ref.read(liveMatchProvider(live.match.id).notifier);
    final status = live.match.status;
    return PopupMenuButton<String>(
      key: const Key('match-menu'),
      onSelected: (v) async {
        switch (v) {
          case 'setup':
            context.go('/matches/${live.match.id}/setup');
          case 'start':
            await runAction(context, ctl.startMatch);
          case 'finish':
            if (await confirmDialog(context, message: l.matchFinishConfirm, confirmLabel: l.matchFinish) && context.mounted) {
              await runAction(context, ctl.finishMatch);
            }
        }
      },
      itemBuilder: (_) => [
        if (status != gen.MatchStatus.FINISHED && status != gen.MatchStatus.CANCELLED)
          PopupMenuItem(value: 'setup', key: const Key('menu-setup'), child: Text(l.matchSetup)),
        if (status == gen.MatchStatus.SCHEDULED)
          PopupMenuItem(value: 'start', key: const Key('menu-start'), child: Text(l.matchStart)),
        if (status == gen.MatchStatus.LIVE)
          PopupMenuItem(value: 'finish', key: const Key('menu-finish'), child: Text(l.matchFinish)),
      ],
    );
  }
}

class _LiveBody extends StatelessWidget {
  const _LiveBody({required this.live, required this.clock});
  final LiveMatch live;
  final GameClock clock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: live.finished ? 2 : 0,
      child: Column(
        children: [
          const SyncBanner(),
          _ScoreHeader(live: live, clock: clock),
          if (live.fromCache) InfoChip(l.matchCachedData, key: const Key('live-cached'), icon: Icons.cloud_off),
          if (live.rights.parentMode)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceXs),
              child: InfoChip(l.matchParentMode, key: const Key('parent-mode'), icon: Icons.family_restroom),
            )
          else if (!live.rights.canScore)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceXs),
              child: InfoChip(l.matchReadOnly, key: const Key('read-only')),
            ),
          TabBar(
            tabs: [
              Tab(key: const Key('tab-court'), text: l.matchTabCourt),
              Tab(key: const Key('tab-log'), text: l.matchTabLog),
              Tab(key: const Key('tab-box'), text: l.matchTabBox),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CourtPanel(live: live, clock: clock),
                _EventLog(live: live),
                BoxScoreView(live: live),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ header

class _ScoreHeader extends ConsumerWidget {
  const _ScoreHeader({required this.live, required this.clock});
  final LiveMatch live;
  final GameClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = live.projection;
    final staff = live.rights.canRunMatch && !live.finished;
    final ctl = ref.read(liveMatchProvider(live.match.id).notifier);
    final period = p.live.period == 0 ? l.matchBeforeStart : periodLabel(l, p.live.period, live.rules.periodCount);
    final scoreStyle = theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, AppTokens.spaceSm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(children: [
                    Text(l.matchUs, style: theme.textTheme.labelMedium),
                    Text('${live.team.teamScore}', key: const Key('score-team'), style: scoreStyle),
                  ]),
                ),
                Column(
                  children: [
                    Text(period, key: const Key('period-label'), style: theme.textTheme.titleMedium),
                    if (staff) _ClockControl(clock: clock) else statusChip(l, live.match.status),
                  ],
                ),
                Expanded(
                  child: Column(children: [
                    Text(live.match.opponentName, style: theme.textTheme.labelMedium, overflow: TextOverflow.ellipsis),
                    Text('${live.team.opponentScore}', key: const Key('score-opponent'), style: scoreStyle),
                  ]),
                ),
              ],
            ),
            if (staff) ...[
              const SizedBox(height: AppTokens.spaceSm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (p.live.running)
                      _HeaderButton(
                        key: const Key('period-end'),
                        icon: Icons.stop_circle_outlined,
                        label: l.matchEndPeriod(period),
                        onPressed: () async {
                          clock.pause();
                          await runAction(context, () => ctl.endPeriod(clock: clock.remaining));
                        },
                      )
                    else
                      _HeaderButton(
                        key: const Key('period-start'),
                        icon: Icons.play_circle_outline,
                        label: l.matchStartPeriod(periodLabel(l, live.nextPeriod, live.rules.periodCount)),
                        onPressed: () async {
                          final seconds = live.rules.periodSeconds(live.nextPeriod);
                          clock.set(seconds);
                          await runAction(context, () => ctl.startPeriod(clock: seconds));
                        },
                      ),
                    for (final points in const [1, 2, 3])
                      _HeaderButton(
                        key: Key('opponent-$points'),
                        label: l.matchOpponentPoints(points),
                        onPressed: () => runAction(context, () => ctl.opponentScore(points, clock: clock.remaining)),
                      ),
                    PopupMenuButton<TimeoutSide>(
                      key: const Key('timeout-menu'),
                      tooltip: l.matchTimeoutOwn,
                      icon: const Icon(Icons.timer_outlined),
                      onSelected: (side) {
                        clock.pause();
                        runAction(context, () => ctl.timeout(side, clock: clock.remaining));
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: TimeoutSide.own, child: Text(l.matchTimeoutOwn)),
                        PopupMenuItem(value: TimeoutSide.opponent, child: Text(l.matchTimeoutOpponent)),
                      ],
                    ),
                    _UndoButton(matchId: live.match.id),
                  ],
                ),
              ),
            ] else if (live.rights.parentMode && !live.finished)
              Align(alignment: Alignment.centerRight, child: _UndoButton(matchId: live.match.id)),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: AppTokens.spaceXs),
    child: SizedBox(
      height: AppTokens.minTapTarget,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(icon), label: Text(label)),
    ),
  );
}

class _UndoButton extends ConsumerWidget {
  const _UndoButton({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return IconButton(
      key: const Key('undo'),
      tooltip: l.matchUndo,
      icon: const Icon(Icons.undo),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        var done = false;
        final ok = await runAction(context, () async => done = await ref.read(liveMatchProvider(matchId).notifier).undo());
        if (ok) messenger.showSnackBar(SnackBar(content: Text(done ? l.matchUndone : l.matchNothingToUndo)));
      },
    );
  }
}

class _ClockControl extends StatelessWidget {
  const _ClockControl({required this.clock});
  final GameClock clock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) => Row(
        key: const Key('game-clock'),
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('clock-minus'),
            tooltip: l.matchClockMinus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove),
            onPressed: () => clock.adjust(-10),
          ),
          Text(formatClock(clock.remaining), key: const Key('clock-value'), style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            key: const Key('clock-plus'),
            tooltip: l.matchClockPlus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add),
            onPressed: () => clock.adjust(10),
          ),
          IconButton.filledTonal(
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

// ------------------------------------------------------------------- court

class _CourtPanel extends ConsumerWidget {
  const _CourtPanel({required this.live, required this.clock});
  final LiveMatch live;
  final GameClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (!live.rights.canRunMatch) {
      // Filtered feed (ADR-0028): other players' substitutions are not in it,
      // so who is on court is unknown; one list, the linked player tappable.
      return ListView(
        key: const Key('court-panel'),
        padding: const EdgeInsets.all(AppTokens.spaceSm),
        children: [
          _SectionTitle(l.navPlayers, key: const Key('players-all')),
          _PlayerGrid(players: live.roster, live: live, onTap: (p) => _statSheet(context, ref, p)),
        ],
      );
    }
    final onCourt = live.projection.live.onCourt;
    final court = [for (final r in live.roster) if (onCourt.contains(r.playerId)) r];
    final bench = [for (final r in live.roster) if (!onCourt.contains(r.playerId)) r];
    return ListView(
      key: const Key('court-panel'),
      padding: const EdgeInsets.all(AppTokens.spaceSm),
      children: [
        _SectionTitle(l.matchOnCourt),
        _PlayerGrid(players: court, live: live, onTap: (p) => _statSheet(context, ref, p)),
        const SizedBox(height: AppTokens.spaceSm),
        _SectionTitle(l.matchBench),
        _PlayerGrid(
          players: bench,
          live: live,
          bench: true,
          onTap: (p) => live.rights.canRunMatch ? _subSheet(context, ref, p, court) : _statSheet(context, ref, p),
        ),
      ],
    );
  }

  int? get _clockValue => live.rights.canRunMatch ? clock.remaining : null;

  Future<void> _statSheet(BuildContext context, WidgetRef ref, RosterPlayer p) async {
    final l = AppLocalizations.of(context);
    final action = await showModalBottomSheet<StatAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, 0, AppTokens.spaceMd, AppTokens.spaceMd),
          child: Column(
            key: const Key('action-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.matchStatsFor(p.displayName), style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: AppTokens.spaceSm),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: AppTokens.spaceXs,
                crossAxisSpacing: AppTokens.spaceXs,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final a in StatAction.values)
                    FilledButton.tonal(
                      key: Key('action-${a.code}'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                      onPressed: () => Navigator.pop(ctx, a),
                      child: Text(actionLabel(l, a), textAlign: TextAlign.center, maxLines: 2),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => ref.read(liveMatchProvider(live.match.id).notifier).recordStat(p.playerId, action, clock: _clockValue),
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l.matchRecorded(actionLabel(l, action), p.displayName)),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  Future<void> _subSheet(BuildContext context, WidgetRef ref, RosterPlayer incoming, List<RosterPlayer> court) async {
    final l = AppLocalizations.of(context);
    final out = await showModalBottomSheet<RosterPlayer>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          key: const Key('sub-sheet'),
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l.matchSubFor(incoming.displayName))),
            for (final p in court)
              ListTile(
                key: Key('sub-out-${p.playerId}'),
                leading: CircleAvatar(child: Text(p.jerseyNumber ?? '-')),
                title: Text(p.displayName),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (out == null || !context.mounted) return;
    await runAction(
      context,
      () => ref.read(liveMatchProvider(live.match.id).notifier).substitute(out: out.playerId, into: incoming.playerId, clock: clock.remaining),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceXs, vertical: AppTokens.spaceXs),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _PlayerGrid extends StatelessWidget {
  const _PlayerGrid({required this.players, required this.live, required this.onTap, this.bench = false});
  final List<RosterPlayer> players;
  final LiveMatch live;
  final bool bench;
  final void Function(RosterPlayer) onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 600 ? 5 : 2;
      final width = (c.maxWidth - (columns - 1) * AppTokens.spaceXs) / columns;
      return Wrap(
        spacing: AppTokens.spaceXs,
        runSpacing: AppTokens.spaceXs,
        children: [for (final p in players) SizedBox(width: width, child: _PlayerTile(player: p, live: live, bench: bench, onTap: onTap))],
      );
    },
  );
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.live, required this.bench, required this.onTap});
  final RosterPlayer player;
  final LiveMatch live;
  final bool bench;
  final void Function(RosterPlayer) onTap;

  bool get _enabled {
    if (live.finished) return false;
    final r = live.rights;
    if (r.canRunMatch) return true;
    return r.canRecordFor(player.playerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = live.projection.lineOf(player.playerId)?.stats;
    final enabled = _enabled;
    return Card(
      margin: EdgeInsets.zero,
      color: bench ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
      child: InkWell(
        key: Key('player-${player.playerId}'),
        onTap: enabled ? () => onTap(player) : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, child: Text(player.jerseyNumber ?? '-')),
                  const SizedBox(width: AppTokens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                        if (live.rights.canSeeLine(player.playerId))
                          Text('${stats?.points ?? 0} PTS · ${stats?.personalFouls ?? 0} PF', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- log

class _EventLog extends ConsumerWidget {
  const _EventLog({required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (live.log.isEmpty) return EmptyView(message: l.matchBeforeStart);
    final ctl = ref.read(liveMatchProvider(live.match.id).notifier);
    final theme = Theme.of(context);
    return ListView.separated(
      key: const Key('event-log'),
      itemCount: live.log.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = live.log[i];
        final rejected = e.status == EventStatus.rejected;
        final meta = e.event.meta;
        return ListTile(
          key: Key('log-${e.event.id}'),
          leading: SizedBox(
            width: 48,
            child: Text(
              '${periodLabel(l, meta.period, live.rules.periodCount)}\n${formatClock(meta.clockSecondsRemaining)}',
              style: theme.textTheme.labelSmall,
            ),
          ),
          title: Text(
            describeEvent(l, live, e.event),
            style: e.voided ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
          ),
          subtitle: Text(
            [if (e.voided) l.matchVoided, syncLabel(l, e)].join(' · '),
            key: Key('log-state-${e.event.id}'),
            style: rejected ? TextStyle(color: theme.colorScheme.error) : null,
          ),
          trailing: rejected && e.mine
              ? IconButton(
                  key: Key('log-discard-${e.event.id}'),
                  tooltip: l.matchDiscard,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirmDialog(context, message: l.matchDiscardConfirm, confirmLabel: l.matchDiscard) &&
                        context.mounted) {
                      await runAction(context, () => ctl.discard(e.event.id));
                    }
                  },
                )
              : e.canVoid && (!live.finished || live.rights.canRunMatch)
              ? IconButton(
                  key: Key('log-void-${e.event.id}'),
                  tooltip: l.matchVoidEvent,
                  icon: const Icon(Icons.block),
                  onPressed: () async {
                    if (await confirmDialog(context, message: l.matchVoidConfirm, confirmLabel: l.matchVoidEvent) &&
                        context.mounted) {
                      await runAction(context, () => ctl.voidEvent(e.event.id));
                    }
                  },
                )
              : null,
        );
      },
    );
  }
}
