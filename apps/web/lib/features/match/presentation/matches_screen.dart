import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;
import 'package:intl/intl.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/presentation/season_bar.dart';
import '../application/match_providers.dart';
import 'match_edit_dialog.dart';
import 'match_labels.dart';
import 'sync_banner.dart';

/// Room under the last row so the extended FAB never covers it.
const _fabClearance = HoopsSpace.xxxl + HoopsSpace.lg;

/// Matches of the caller's teams (deferred module behind the Matches tab).
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncTriggersProvider);
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final list = ref.watch(matchListProvider);
    final zone = ref.watch(tenantZoneProvider).label;
    final width = WidthClass.of(context);
    return Scaffold(
      floatingActionButton: caps.canCreateMatches
          ? FloatingActionButton.extended(
              key: const Key('match-new'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const MatchCreateDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.matchNew),
            )
          : null,
      body: Column(
        children: [
          const SyncBanner(),
          Padding(
            padding: EdgeInsets.only(top: width.sectionGap),
            child: ContentFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: l.navMatches,
                    subtitle: zone == null ? null : l.timesShownIn(zone),
                  ),
                  const SeasonBar(),
                  if (caps.canSeeModule) ...[
                    const SizedBox(height: HoopsSpace.md),
                    const _TeamFilter(),
                  ],
                  if (list.value?.fromCache ?? false) ...[
                    const SizedBox(height: HoopsSpace.gap),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(
                        l.matchCachedData,
                        key: const Key('match-list-cached'),
                        tone: HoopsTone.warning,
                        icon: Icons.cloud_off,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<MatchList>(
              value: list,
              onRetry: () => ref.invalidate(matchListProvider),
              isEmpty: (d) => d.matches.isEmpty,
              emptyMessage: l.matchListEmpty,
              builder: (context, data) => RefreshIndicator(
                onRefresh: () => ref.refresh(matchListProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    top: HoopsSpace.md,
                    bottom: _fabClearance,
                  ),
                  itemCount: data.matches.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: HoopsSpace.gap),
                  itemBuilder: (context, i) =>
                      ContentFrame(child: MatchTile(match: data.matches[i])),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamFilter extends ConsumerWidget {
  const _TeamFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final teams = ref.watch(teamsProvider).value ?? const <api.Team>[];
    final selected = ref.watch(matchTeamFilterProvider);
    return DropdownButtonFormField<String?>(
      key: const Key('match-team-filter'),
      initialValue: teams.any((t) => t.id == selected) ? selected : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.matchTeam),
      items: [
        DropdownMenuItem<String?>(child: Text(l.matchAllTeams)),
        for (final t in teams)
          DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
      ],
      onChanged: (v) => ref.read(matchTeamFilterProvider.notifier).select(v),
    );
  }
}

/// One match on its card: opponent, kick-off (academy zone), home / away,
/// the state chip and, once played, the score.
class MatchTile extends ConsumerWidget {
  const MatchTile({super.key, required this.match});
  final gen.Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(ref.watch(tenantZoneProvider).wall(match.scheduledAt));
    final played =
        match.status == gen.MatchStatus.LIVE ||
        match.status == gen.MatchStatus.FINISHED;
    final canEdit =
        match.status != gen.MatchStatus.CANCELLED &&
        ref.watch(capabilitiesProvider).canRunMatch(match.teamId);
    return ListRow(
      key: Key('match-${match.id}'),
      // Phones give the opponent and the kick-off the whole width.
      leading: WidthClass.of(context).isCompact
          ? null
          : InitialsAvatar(
              name: match.opponentName,
              tone: match.status == gen.MatchStatus.LIVE
                  ? HoopsTone.accent
                  : HoopsTone.neutral,
            ),
      title: l.matchVs(match.opponentName),
      subtitle:
          '$when · ${match.homeAway == gen.HomeAway.AWAY ? l.matchAway : l.matchHome}',
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          statusChip(l, match.status),
          if (played) ...[
            const SizedBox(height: HoopsSpace.xs),
            Text(
              '${match.score.team} – ${match.score.opponent}',
              style: tabular(text.titleMedium!),
            ),
          ],
        ],
      ),
      details: canEdit
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: Key('match-edit-${match.id}'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.matchEdit),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => MatchEditDialog(
                    match: match,
                    save: (e) => ref
                        .read(matchListProvider.notifier)
                        .updateMatch(
                          match.id,
                          opponentName: e.opponentName,
                          scheduledAt: e.scheduledAt,
                          homeAway: e.homeAway,
                          venue: e.venue,
                          periodCount: e.periodCount,
                          periodMinutes: e.periodMinutes,
                        ),
                  ),
                ),
              ),
            )
          : null,
      onTap: () => context.go('/matches/${match.id}'),
    );
  }
}

/// Schedules a match for one of the caller's teams.
class MatchCreateDialog extends ConsumerStatefulWidget {
  const MatchCreateDialog({super.key});

  @override
  ConsumerState<MatchCreateDialog> createState() => _MatchCreateDialogState();
}

class _MatchCreateDialogState extends ConsumerState<MatchCreateDialog> {
  final _form = GlobalKey<FormState>();
  final _opponent = TextEditingController();
  String? _teamId;
  gen.HomeAway _homeAway = gen.HomeAway.HOME;
  late final DateTime _today = ref
      .read(tenantZoneProvider)
      .today(DateTime.now());
  late DateTime _date = _today.add(const Duration(days: 1));

  @override
  void dispose() {
    _opponent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final teams = [
      for (final t in ref.watch(teamsProvider).value ?? const <api.Team>[])
        if (caps.canRunMatch(t.id)) t,
    ];
    _teamId ??= teams.isEmpty ? null : teams.first.id;
    return FormDialog(
      title: l.matchNew,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(matchListProvider.notifier)
            .create(
              teamId: _teamId!,
              opponentName: _opponent.text.trim(),
              homeAway: _homeAway,
              scheduledAt: ref
                  .read(tenantZoneProvider)
                  .instant(DateTime(_date.year, _date.month, _date.day, 10)),
            ),
        success: l.matchCreated,
      ),
      children: [
        DropdownButtonFormField<String>(
          key: const Key('match-new-team'),
          initialValue: _teamId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.matchTeam),
          items: [
            for (final t in teams)
              DropdownMenuItem(value: t.id, child: Text(t.name)),
          ],
          validator: (v) => v == null ? l.fieldRequired : null,
          onChanged: (v) => setState(() => _teamId = v),
        ),
        formGap,
        TextFormField(
          key: const Key('match-new-opponent'),
          controller: _opponent,
          decoration: InputDecoration(labelText: l.matchOpponent),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        SegmentedButton<gen.HomeAway>(
          segments: [
            ButtonSegment(value: gen.HomeAway.HOME, label: Text(l.matchHome)),
            ButtonSegment(value: gen.HomeAway.AWAY, label: Text(l.matchAway)),
          ],
          selected: {_homeAway},
          onSelectionChanged: (s) => setState(() => _homeAway = s.single),
        ),
        formGap,
        DateField(
          key: const Key('match-new-date'),
          label: l.matchDate,
          value: _date,
          firstDate: _today.subtract(const Duration(days: 365)),
          lastDate: _today.add(const Duration(days: 365)),
          onChanged: (d) =>
              setState(() => _date = DateTime(d.year, d.month, d.day)),
        ),
      ],
    );
  }
}
