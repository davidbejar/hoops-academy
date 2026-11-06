import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/game_clock.dart';
import '../application/live_match_controller.dart';
import '../application/match_providers.dart';
import 'box_score_view.dart';
import 'court_panel.dart';
import 'event_log.dart';
import 'live_scoreboard.dart';
import 'match_edit_dialog.dart';
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
        builder: (context, m) => m.roster.isEmpty
            ? _NoRoster(live: m)
            : _LiveBody(live: m, clock: _clock),
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
    return EmptyState(
      icon: Icons.groups_outlined,
      title: l.matchNoRoster,
      action: live.rights.canRunMatch
          ? FilledButton.icon(
              key: const Key('open-setup'),
              onPressed: () => context.go('/matches/${live.match.id}/setup'),
              icon: const Icon(Icons.groups),
              label: Text(l.matchSetupAction),
            )
          : null,
    );
  }
}

enum _MenuAction { setup, edit, start, finish }

/// The staff's match actions, as a sheet near the thumb on phones.
class _StaffMenu extends ConsumerWidget {
  const _StaffMenu({required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    key: const Key('match-menu'),
    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
    icon: const Icon(Icons.more_vert),
    onPressed: () => _open(context, ref),
  );

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final status = live.match.status;
    final open =
        status != gen.MatchStatus.FINISHED &&
        status != gen.MatchStatus.CANCELLED;
    final choice = await showActionSheet<_MenuAction>(
      context,
      title: l.matchVs(live.match.opponentName),
      actions: [
        if (open)
          SheetAction(
            key: const Key('menu-setup'),
            icon: Icons.groups_outlined,
            label: l.matchSetup,
            value: _MenuAction.setup,
          ),
        if (status != gen.MatchStatus.CANCELLED)
          SheetAction(
            key: const Key('menu-edit'),
            icon: Icons.edit_outlined,
            label: l.matchEdit,
            value: _MenuAction.edit,
          ),
        if (status == gen.MatchStatus.SCHEDULED)
          SheetAction(
            key: const Key('menu-start'),
            icon: Icons.play_arrow_rounded,
            label: l.matchStart,
            value: _MenuAction.start,
          ),
        if (status == gen.MatchStatus.LIVE)
          SheetAction(
            key: const Key('menu-finish'),
            icon: Icons.flag_outlined,
            label: l.matchFinish,
            value: _MenuAction.finish,
          ),
      ],
    );
    if (choice == null || !context.mounted) return;
    final ctl = ref.read(liveMatchProvider(live.match.id).notifier);
    switch (choice) {
      case _MenuAction.setup:
        context.go('/matches/${live.match.id}/setup');
      case _MenuAction.edit:
        await showDialog<bool>(
          context: context,
          builder: (_) => MatchEditDialog(
            match: live.match,
            save: (e) => ctl.updateMatch(
              opponentName: e.opponentName,
              scheduledAt: e.scheduledAt,
              homeAway: e.homeAway,
              venue: e.venue,
              periodCount: e.periodCount,
              periodMinutes: e.periodMinutes,
            ),
          ),
        );
      case _MenuAction.start:
        await runAction(context, ctl.startMatch);
      case _MenuAction.finish:
        if (await confirmDialog(
              context,
              message: l.matchFinishConfirm,
              confirmLabel: l.matchFinish,
            ) &&
            context.mounted) {
          await runAction(context, ctl.finishMatch);
        }
    }
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
          LiveScoreboard(live: live, clock: clock),
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
                CourtPanel(live: live, clock: clock),
                EventLog(live: live),
                BoxScoreView(live: live),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
