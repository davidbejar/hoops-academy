import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/game_clock.dart';
import '../application/live_match_controller.dart';
import '../domain/projector/projector.dart';
import '../domain/stat_action.dart';
import 'match_labels.dart';

/// Narrowest player tile: two columns on a phone, four from tablets.
const _playerTileMinWidth = 150.0;

/// Tiles of players the caller cannot score for are dimmed.
const _disabledOpacity = 0.45;

/// Height of a stat button: a comfortable court-side target.
const _statButtonHeight = HoopsSize.minTapTarget + HoopsSpace.sm;

/// The court tab: who is on court and on the bench (staff), or the whole
/// roster (filtered feed). Tapping a player opens the stat sheet; tapping a
/// bench player (staff) opens the substitution sheet.
class CourtPanel extends ConsumerWidget {
  const CourtPanel({super.key, required this.live, required this.clock});
  final LiveMatch live;
  final GameClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final gutter = WidthClass.of(context).gutter;
    final padding = EdgeInsets.fromLTRB(
      gutter,
      HoopsSpace.sm,
      gutter,
      HoopsSpace.lg,
    );
    if (!live.rights.canRunMatch) {
      // Filtered feed (ADR-0030): other players' substitutions are not in it,
      // so who is on court is unknown; one list, the linked player tappable.
      return ListView(
        key: const Key('court-panel'),
        padding: padding,
        children: [
          _SectionTitle(l.navPlayers, key: const Key('players-all')),
          _PlayerGrid(
            players: live.roster,
            live: live,
            onTap: (p) => _statSheet(context, ref, p),
          ),
        ],
      );
    }
    final onCourt = live.projection.live.onCourt;
    final court = [
      for (final r in live.roster)
        if (onCourt.contains(r.playerId)) r,
    ];
    final bench = [
      for (final r in live.roster)
        if (!onCourt.contains(r.playerId)) r,
    ];
    return ListView(
      key: const Key('court-panel'),
      padding: padding,
      children: [
        _SectionTitle(l.matchOnCourt),
        _PlayerGrid(
          players: court,
          live: live,
          onTap: (p) => _statSheet(context, ref, p),
        ),
        const SizedBox(height: HoopsSpace.md),
        _SectionTitle(l.matchBench),
        _PlayerGrid(
          players: bench,
          live: live,
          bench: true,
          onTap: (p) => _subSheet(context, ref, p, court),
        ),
      ],
    );
  }

  int? get _clockValue => live.rights.canRunMatch ? clock.remaining : null;

  Future<void> _statSheet(
    BuildContext context,
    WidgetRef ref,
    RosterPlayer p,
  ) async {
    final l = AppLocalizations.of(context);
    final action = await showModalBottomSheet<StatAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatEntrySheet(player: p),
    );
    if (action == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => ref
          .read(liveMatchProvider(live.match.id).notifier)
          .recordStat(p.playerId, action, clock: _clockValue),
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l.matchRecorded(actionLabel(l, action), p.displayName),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _subSheet(
    BuildContext context,
    WidgetRef ref,
    RosterPlayer incoming,
    List<RosterPlayer> court,
  ) async {
    final l = AppLocalizations.of(context);
    final out = await showActionSheet<RosterPlayer>(
      context,
      title: l.matchSubFor(incoming.displayName),
      actions: [
        for (final p in court)
          SheetAction(
            key: Key('sub-out-${p.playerId}'),
            icon: Icons.swap_horiz,
            label: p.displayName,
            subtitle: p.jerseyNumber == null ? null : '#${p.jerseyNumber}',
            value: p,
          ),
      ],
    );
    if (out == null || !context.mounted) return;
    await runAction(
      context,
      () => ref
          .read(liveMatchProvider(live.match.id).notifier)
          .substitute(
            out: out.playerId,
            into: incoming.playerId,
            clock: clock.remaining,
          ),
    );
  }
}

/// The stat buttons for one player, in the lower half of the screen: shots
/// as made / missed pairs, then the other plays, then the fouls.
class StatEntrySheet extends StatelessWidget {
  const StatEntrySheet({super.key, required this.player});
  final RosterPlayer player;

  static const _shots = [
    [StatAction.twoMade, StatAction.twoMissed],
    [StatAction.threeMade, StatAction.threeMissed],
    [StatAction.ftMade, StatAction.ftMissed],
  ];
  static const _plays = [
    [
      StatAction.assist,
      StatAction.offensiveRebound,
      StatAction.defensiveRebound,
    ],
    [StatAction.steal, StatAction.block, StatAction.turnover],
  ];
  static const _fouls = [
    [
      StatAction.foulPersonal,
      StatAction.foulTechnical,
      StatAction.foulUnsportsmanlike,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          HoopsSpace.lg,
          0,
          HoopsSpace.lg,
          HoopsSpace.lg,
        ),
        child: Column(
          key: const Key('action-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InitialsAvatar(name: player.jerseyNumber ?? '-'),
                const SizedBox(width: HoopsSpace.gap),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.matchStatsFor(player.displayName),
                      style: text.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HoopsSpace.md),
            for (final (i, group) in [_shots, _plays, _fouls].indexed) ...[
              if (i > 0) const SizedBox(height: HoopsSpace.md),
              for (final (j, row) in group.indexed) ...[
                if (j > 0) const SizedBox(height: HoopsSpace.sm),
                Row(
                  spacing: HoopsSpace.sm,
                  children: [
                    for (final a in row) Expanded(child: _StatButton(a)),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

enum _StatKind { made, missed, play, foul }

class _StatButton extends StatelessWidget {
  const _StatButton(this.action);
  final StatAction action;

  _StatKind get _kind => switch (action) {
    StatAction.twoMade ||
    StatAction.threeMade ||
    StatAction.ftMade => _StatKind.made,
    StatAction.twoMissed ||
    StatAction.threeMissed ||
    StatAction.ftMissed => _StatKind.missed,
    StatAction.foulPersonal ||
    StatAction.foulTechnical ||
    StatAction.foulUnsportsmanlike => _StatKind.foul,
    _ => _StatKind.play,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final label = Text(
      actionLabel(l, action),
      textAlign: TextAlign.center,
      maxLines: 2,
    );
    void choose() => Navigator.pop(context, action);
    final key = Key('action-${action.code}');
    const padding = EdgeInsets.symmetric(horizontal: HoopsSpace.xs);
    final button = switch (_kind) {
      _StatKind.made => FilledButton(
        key: key,
        style: FilledButton.styleFrom(padding: padding),
        onPressed: choose,
        child: label,
      ),
      _StatKind.missed => OutlinedButton(
        key: key,
        style: OutlinedButton.styleFrom(padding: padding),
        onPressed: choose,
        child: label,
      ),
      _StatKind.play => FilledButton.tonal(
        key: key,
        style: FilledButton.styleFrom(padding: padding),
        onPressed: choose,
        child: label,
      ),
      _StatKind.foul => FilledButton.tonal(
        key: key,
        style: FilledButton.styleFrom(
          padding: padding,
          backgroundColor: c.danger.container,
          foregroundColor: c.danger.onContainer,
        ),
        onPressed: choose,
        child: label,
      ),
    };
    return SizedBox(height: _statButtonHeight, child: button);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HoopsSpace.xs),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
  );
}

class _PlayerGrid extends StatelessWidget {
  const _PlayerGrid({
    required this.players,
    required this.live,
    required this.onTap,
    this.bench = false,
  });
  final List<RosterPlayer> players;
  final LiveMatch live;
  final bool bench;
  final void Function(RosterPlayer) onTap;

  @override
  Widget build(BuildContext context) => ResponsiveGrid(
    minTileWidth: _playerTileMinWidth,
    spacing: HoopsSpace.sm,
    children: [
      for (final p in players)
        _PlayerTile(player: p, live: live, bench: bench, onTap: onTap),
    ],
  );
}

/// A player on court (soft orange, the jersey number large) or on the bench
/// (card, the number in a badge), with points and fouls when visible.
class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.live,
    required this.bench,
    required this.onTap,
  });
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
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final stats = live.projection.lineOf(player.playerId)?.stats;
    final enabled = _enabled;
    final ink = bench ? c.ink : c.onAccentSoft;
    final jersey = player.jerseyNumber ?? '-';
    return Material(
      color: bench ? c.surface : c.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.md),
        side: BorderSide(color: bench ? c.border : c.accentSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('player-${player.playerId}'),
        onTap: enabled ? () => onTap(player) : null,
        child: Opacity(
          opacity: enabled ? 1 : _disabledOpacity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: HoopsSpace.xxxl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HoopsSpace.gap,
                vertical: HoopsSpace.sm,
              ),
              child: Row(
                children: [
                  if (bench)
                    InitialsAvatar(name: jersey)
                  else
                    SizedBox(
                      width: HoopsSize.avatar,
                      child: Text(
                        jersey,
                        textAlign: TextAlign.center,
                        style: tabular(text.titleLarge!).copyWith(color: ink),
                      ),
                    ),
                  const SizedBox(width: HoopsSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall!.copyWith(color: ink),
                        ),
                        if (live.rights.canSeeLine(player.playerId))
                          Text(
                            '${stats?.points ?? 0} PTS · ${stats?.personalFouls ?? 0} PF',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(
                              color: bench ? c.inkMuted : ink,
                            ),
                          ),
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
