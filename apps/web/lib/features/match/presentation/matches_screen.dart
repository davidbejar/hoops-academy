import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../core/ui/timezone_note.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../application/match_providers.dart';
import 'match_labels.dart';
import 'sync_banner.dart';

/// Matches of the caller's teams (deferred module behind the Matches tab).
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncTriggersProvider);
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final list = ref.watch(matchListProvider);
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
          const TimezoneNote(),
          if (caps.canSeeModule) const _TeamFilter(),
          if (list.value?.fromCache ?? false)
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              child: InfoChip(
                l.matchCachedData,
                key: const Key('match-list-cached'),
                icon: Icons.cloud_off,
              ),
            ),
          Expanded(
            child: AsyncBody<MatchList>(
              value: list,
              onRetry: () => ref.invalidate(matchListProvider),
              isEmpty: (d) => d.matches.isEmpty,
              emptyMessage: l.matchListEmpty,
              builder: (context, data) => Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTokens.maxContentWidth,
                  ),
                  child: RefreshIndicator(
                    onRefresh: () => ref.refresh(matchListProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: data.matches.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          MatchTile(match: data.matches[i]),
                    ),
                  ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spaceMd,
        AppTokens.spaceMd,
        AppTokens.spaceMd,
        0,
      ),
      child: DropdownButtonFormField<String?>(
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
      ),
    );
  }
}

class MatchTile extends ConsumerWidget {
  const MatchTile({super.key, required this.match});
  final gen.Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(ref.watch(tenantZoneProvider).wall(match.scheduledAt));
    final played =
        match.status == gen.MatchStatus.LIVE ||
        match.status == gen.MatchStatus.FINISHED;
    return ListTile(
      key: Key('match-${match.id}'),
      minVerticalPadding: AppTokens.spaceSm,
      leading: const CircleAvatar(child: Icon(Icons.sports_basketball)),
      title: Text(l.matchVs(match.opponentName)),
      subtitle: Text(
        '$when · ${match.homeAway == gen.HomeAway.AWAY ? l.matchAway : l.matchHome}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          statusChip(l, match.status),
          if (played)
            Text(
              '${match.score.team} – ${match.score.opponent}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
        ],
      ),
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
  late DateTime _date = ref
      .read(tenantZoneProvider)
      .today(DateTime.now())
      .add(const Duration(days: 1));

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
        TextFormField(
          key: const Key('match-new-opponent'),
          controller: _opponent,
          decoration: InputDecoration(labelText: l.matchOpponent),
          validator: (v) => (v ?? '').trim().isEmpty ? l.fieldRequired : null,
        ),
        SegmentedButton<gen.HomeAway>(
          segments: [
            ButtonSegment(value: gen.HomeAway.HOME, label: Text(l.matchHome)),
            ButtonSegment(value: gen.HomeAway.AWAY, label: Text(l.matchAway)),
          ],
          selected: {_homeAway},
          onSelectionChanged: (s) => setState(() => _homeAway = s.single),
        ),
        ListTile(
          key: const Key('match-new-date'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.matchDate),
          subtitle: Text(
            DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                .format(_date),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final today = ref.read(tenantZoneProvider).today(DateTime.now());
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: today.subtract(const Duration(days: 365)),
              lastDate: today.add(const Duration(days: 365)),
            );
            if (picked != null)
              setState(
                () => _date = DateTime(picked.year, picked.month, picked.day),
              );
          },
        ),
      ],
    );
  }
}
