import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../application/live_match_controller.dart';
import '../application/match_providers.dart';
import '../../health/presentation/player_health_view.dart'
    show AvailabilityBadge;
import '../data/matches_repository.dart';
import '../domain/pending_event.dart';
import '../domain/projector/projector.dart';

/// Room for a two-digit jersey number and its label.
const _jerseyFieldWidth = HoopsSpace.xxxl + HoopsSpace.md;

class SetupData {
  const SetupData(this.match, this.teamRoster, this.matchRoster);
  final gen.Match match;
  final List<api.TeamPlayer> teamRoster;
  final List<RosterPlayer> matchRoster;
}

/// Match + the team's current roster (core) + the stored match roster.
final matchSetupProvider = FutureProvider.family<SetupData, String>((
  ref,
  matchId,
) async {
  final repo = ref.watch(matchesRepositoryProvider);
  final match = await repo.get(matchId);
  final results = await Future.wait<Object>([
    ref.watch(teamsRepositoryProvider).roster(match.teamId),
    repo.roster(matchId),
  ]);
  return SetupData(
    match,
    results[0] as List<api.TeamPlayer>,
    results[1] as List<RosterPlayer>,
  );
});

/// Match roster: who plays, starters, jersey numbers (staff only, online).
class MatchSetupScreen extends ConsumerWidget {
  const MatchSetupScreen({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(matchSetupProvider(matchId));
    final caps = ref.watch(capabilitiesProvider);
    return SubPage(
      title: l.matchSetup,
      parentPath: '/matches/$matchId',
      child: AsyncBody<SetupData>(
        value: data,
        onRetry: () => ref.invalidate(matchSetupProvider(matchId)),
        isEmpty: (d) => d.teamRoster.isEmpty,
        emptyMessage: l.matchSetupNoPlayers,
        builder: (context, d) => Guarded(
          allowed: caps.canRunMatch(d.match.teamId),
          child: _SetupForm(data: d),
        ),
      ),
    );
  }
}

class _Line {
  _Line({
    required this.selected,
    required this.starter,
    required String? jersey,
  }) : jersey = TextEditingController(text: jersey ?? '');
  bool selected;
  bool starter;
  final TextEditingController jersey;
}

class _SetupForm extends ConsumerStatefulWidget {
  const _SetupForm({required this.data});
  final SetupData data;

  @override
  ConsumerState<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends ConsumerState<_SetupForm> {
  late final Map<String, _Line> _lines;
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = {for (final r in widget.data.matchRoster) r.playerId: r};
    _lines = {
      for (final p in widget.data.teamRoster)
        p.player.id: _Line(
          selected: existing.isEmpty || existing.containsKey(p.player.id),
          starter: existing[p.player.id]?.isStarter ?? false,
          jersey: existing[p.player.id]?.jerseyNumber ?? p.jerseyNumber,
        ),
    };
  }

  @override
  void dispose() {
    for (final line in _lines.values) {
      line.jersey.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    final chosen = _lines.entries.where((e) => e.value.selected).toList();
    if (!chosen.any((e) => e.value.starter)) {
      setState(() => _error = l.matchSetupNeedStarter);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final matchId = widget.data.match.id;
    final ok = await runAction(context, () async {
      final saved = await ref.read(matchesRepositoryProvider).replaceRoster(
        matchId,
        [
          for (final e in chosen)
            RosterInput(
              playerId: e.key,
              jerseyNumber: e.value.jersey.text.trim().isEmpty
                  ? null
                  : e.value.jersey.text.trim(),
              isStarter: e.value.starter,
            ),
        ],
      );
      await ref.read(matchStoreProvider).saveRoster(matchId, [
        for (final r in saved)
          CachedRosterEntry(
            playerId: r.playerId,
            displayName: r.displayName,
            jerseyNumber: r.jerseyNumber,
            isStarter: r.isStarter,
          ),
      ], tenantId: ref.read(api.tenantIdProvider));
    }, success: l.matchSetupSaved);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.invalidate(liveMatchProvider(matchId));
      context.go('/matches/$matchId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final selected = _lines.values.where((e) => e.selected).length;
    final starters = _lines.values.where((e) => e.selected && e.starter).length;
    return Form(
      key: _form,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: HoopsSpace.md),
              children: [
                ContentFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: HoopsSpace.xs,
                    children: [
                      Text(
                        l.matchSetupHint,
                        style: text.bodyMedium!.copyWith(color: c.inkMuted),
                      ),
                      Text(
                        l.matchSetupSummary(selected, starters),
                        key: const Key('setup-summary'),
                        style: text.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HoopsSpace.md),
                for (final p in widget.data.teamRoster)
                  Padding(
                    padding: const EdgeInsets.only(bottom: HoopsSpace.sm),
                    child: ContentFrame(
                      child: _row(context, l, p, _lines[p.player.id]!),
                    ),
                  ),
              ],
            ),
          ),
          ContentFrame(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: HoopsSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HoopsSpace.sm,
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      key: const Key('setup-error'),
                      style: text.bodyMedium!.copyWith(
                        color: c.danger.foreground,
                      ),
                    ),
                  SizedBox(
                    height: HoopsSize.minTapTarget,
                    child: FilledButton.icon(
                      key: const Key('setup-save'),
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.check),
                      label: Text(l.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One player on a card: plays (checkbox), availability, jersey, starter.
  Widget _row(
    BuildContext context,
    AppLocalizations l,
    api.TeamPlayer p,
    _Line line,
  ) {
    final c = HoopsTokens.colorsOf(context);
    return DecoratedBox(
      key: Key('setup-${p.player.id}'),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(HoopsRadius.md),
        border: Border.all(color: line.selected ? c.borderStrong : c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HoopsSpace.xs,
          HoopsSpace.sm,
          HoopsSpace.sm,
          HoopsSpace.sm,
        ),
        child: Row(
          children: [
            Checkbox(
              key: Key('setup-include-${p.player.id}'),
              value: line.selected,
              onChanged: (v) => setState(() {
                line.selected = v ?? false;
                if (!line.selected) line.starter = false;
              }),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.player.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  // Information only: the coach decides who plays.
                  AvailabilityBadge(playerId: p.player.id),
                ],
              ),
            ),
            SizedBox(
              width: _jerseyFieldWidth,
              child: TextFormField(
                key: Key('setup-jersey-${p.player.id}'),
                controller: line.jersey,
                enabled: line.selected,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.matchJersey,
                  isDense: true,
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  return t.isEmpty || RegExp(r'^[0-9]{1,2}$').hasMatch(t)
                      ? null
                      : l.fieldRequired;
                },
              ),
            ),
            const SizedBox(width: HoopsSpace.sm),
            FilterChip(
              key: Key('setup-starter-${p.player.id}'),
              label: Text(l.matchStarter),
              selected: line.starter,
              onSelected: line.selected
                  ? (v) => setState(() => line.starter = v)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
