import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart';
import '../application/roster_providers.dart';
import 'eligibility_widgets.dart';

const _filterableStatuses = [
  api.PlayerStatus.ACTIVE,
  api.PlayerStatus.ORPHAN,
  api.PlayerStatus.PENDING_APPROVAL,
  api.PlayerStatus.WITHDRAWN,
];

/// Players list with filters (deferred module behind the Players tab).
class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final filter = ref.watch(playerFilterProvider);
    final players = ref.watch(playersProvider);
    final teams = ref.watch(teamsProvider).value ?? const <api.Team>[];
    final categories =
        ref.watch(ageCategoriesProvider).value ?? const <api.AgeCategory>[];
    void setFilter(PlayerFilter f) =>
        ref.read(playerFilterProvider.notifier).set(f);

    return Scaffold(
      floatingActionButton:
          caps.canCreatePlayerDirectly || caps.canRequestPlayer
          ? FloatingActionButton.extended(
              key: const Key('player-new'),
              onPressed: () => context.go('/players/new'),
              icon: const Icon(Icons.person_add_alt),
              label: Text(
                caps.canCreatePlayerDirectly ? l.playerNew : l.playerNewRequest,
              ),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTokens.maxContentWidth,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceMd,
                  AppTokens.spaceMd,
                  AppTokens.spaceSm,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('player-search'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l.playersSearchHint,
                        ),
                        onSubmitted: (v) =>
                            setFilter(filter.copyWith(query: v.trim())),
                        onChanged: (v) {
                          if (v.isEmpty && filter.query.isNotEmpty) {
                            setFilter(filter.copyWith(query: ''));
                          }
                        },
                      ),
                    ),
                    if (caps.canSeeApprovals)
                      IconButton(
                        key: const Key('open-requests'),
                        tooltip: caps.canDecideApprovals
                            ? l.approvalsTitle
                            : l.approvalsMine,
                        icon: const Icon(Icons.how_to_reg_outlined),
                        onPressed: () => context.go('/players/requests'),
                      ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMd,
                  vertical: AppTokens.spaceSm,
                ),
                child: Row(
                  children: [
                    _FilterMenu<api.PlayerStatus>(
                      keyName: 'filter-status',
                      label: l.filterStatus,
                      value: filter.status,
                      options: {
                        for (final s in _filterableStatuses) s: s.label(l),
                      },
                      onChanged: (v) => setFilter(
                        filter.copyWith(status: v, clearStatus: v == null),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSm),
                    _FilterMenu<String>(
                      keyName: 'filter-team',
                      label: l.filterTeam,
                      value: filter.teamId,
                      options: {for (final t in teams) t.id: t.displayLabel},
                      onChanged: (v) => setFilter(
                        filter.copyWith(teamId: v, clearTeam: v == null),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSm),
                    _FilterMenu<String>(
                      keyName: 'filter-category',
                      label: l.filterCategory,
                      value: filter.categoryId,
                      options: {for (final c in categories) c.id: c.name},
                      onChanged: (v) => setFilter(
                        filter.copyWith(
                          categoryId: v,
                          clearCategory: v == null,
                        ),
                      ),
                    ),
                    if (filter.isActive)
                      TextButton(
                        key: const Key('filter-clear'),
                        onPressed: () => setFilter(const PlayerFilter()),
                        child: Text(l.filterClear),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncBody<List<api.Player>>(
                  value: players,
                  onRetry: () => ref.invalidate(playersProvider),
                  isEmpty: (d) => d.isEmpty,
                  emptyMessage: l.playersEmpty,
                  builder: (context, data) => ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [for (final p in data) PlayerTile(player: p)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterMenu<T extends Object> extends StatelessWidget {
  const _FilterMenu({
    required this.keyName,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String keyName;
  final String label;
  final T? value;
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<T?>(
      key: Key(keyName),
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(value: null, child: Text(l.all)),
        for (final e in options.entries)
          PopupMenuItem<T?>(value: e.key, child: Text(e.value)),
      ],
      child: Chip(
        label: Text(value == null ? label : '$label: ${options[value]}'),
        avatar: const Icon(Icons.filter_list, size: 16),
      ),
    );
  }
}

InfoChip statusChip(api.PlayerStatus status, AppLocalizations l) => InfoChip(
  status.label(l),
  tone: status == api.PlayerStatus.ACTIVE
      ? ChipTone.good
      : status == api.PlayerStatus.WITHDRAWN
      ? ChipTone.neutral
      : ChipTone.warn,
);

class PlayerTile extends StatelessWidget {
  const PlayerTile({super.key, required this.player});
  final api.Player player;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      key: Key('player-${player.id}'),
      leading: CircleAvatar(
        child: Text(player.displayName.isEmpty ? '?' : player.displayName[0]),
      ),
      title: Text(player.displayName),
      subtitle: Text(
        [
          if (player.naturalCategory != null) player.naturalCategory!.name,
          player.teams.map((t) => t.team.name).join(', '),
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
      trailing: statusChip(player.status, l),
      onTap: () => context.go('/players/${player.id}'),
    );
  }
}

// ----------------------------------------------------------------- detail

final _guardiansOfPlayerProvider =
    FutureProvider.family<List<api.GuardianLink>, String>(
      (ref, playerId) => ref
          .watch(membersRepositoryProvider)
          .guardianLinks(playerId: playerId),
    );

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final player = ref.watch(playerDetailProvider(playerId));
    return SubPage(
      title: player.value?.displayName ?? l.navPlayers,
      parentPath: '/players',
      child: AsyncBody<api.Player>(
        value: player,
        onRetry: () => ref.invalidate(playerDetailProvider(playerId)),
        builder: (context, p) => _PlayerDetailBody(player: p, caps: caps),
      ),
    );
  }
}

class _PlayerDetailBody extends ConsumerWidget {
  const _PlayerDetailBody({required this.player, required this.caps});
  final api.Player player;
  final Capabilities caps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canAssign =
        (caps.canCreatePlayerDirectly || caps.canRequestPlayer) &&
        (player.status == api.PlayerStatus.ACTIVE ||
            player.status == api.PlayerStatus.ORPHAN);
    final canWithdraw =
        caps.canWithdrawPlayer &&
        player.status != api.PlayerStatus.WITHDRAWN &&
        player.status != api.PlayerStatus.PENDING_APPROVAL;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                player.displayName.isEmpty ? '?' : player.displayName[0],
              ),
            ),
            const SizedBox(width: AppTokens.spaceMd),
            Expanded(
              child: Text(
                player.displayName,
                style: theme.textTheme.titleLarge,
              ),
            ),
            statusChip(player.status, l),
          ],
        ),
        const SizedBox(height: AppTokens.spaceSm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('player-season-stats'),
            onPressed: () => context.go('/matches/stats/${player.id}'),
            icon: const Icon(Icons.bar_chart),
            label: Text(l.seasonStatsTitle),
          ),
        ),
        const SizedBox(height: AppTokens.spaceLg),
        Text(l.playerBasics, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTokens.spaceSm),
        _Fact(label: l.playerBirthDate, value: formatDate(player.birthDate)),
        _Fact(label: l.playerGender, value: player.gender.label(l)),
        _Fact(
          label: l.playerNaturalCategory,
          value: player.naturalCategory?.name ?? '-',
        ),
        const SizedBox(height: AppTokens.spaceLg),
        Text(l.playerTeams, style: theme.textTheme.titleMedium),
        if (player.teams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
            child: Text(l.playerNoTeams, key: const Key('player-no-teams')),
          ),
        for (final a in player.teams)
          ListTile(
            key: Key('player-team-${a.team.id}'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(a.jerseyNumber ?? '-')),
            title: Text(a.team.name),
            subtitle: Wrap(
              spacing: AppTokens.spaceSm,
              children: [
                if (a.playUpLevels > 0) PlayUpBadge(levels: a.playUpLevels),
                if (!a.valid)
                  InfoChip(
                    l.rosterInvalid,
                    tone: ChipTone.bad,
                    icon: Icons.warning_amber,
                  ),
              ],
            ),
            onTap: () => context.go('/teams/${a.team.id}'),
          ),
        if (canAssign)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('player-assign'),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l.playerAssignToTeam),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => EligibleTeamsDialog(playerId: player.id),
              ),
            ),
          ),
        if (caps.canManageAcademy) ...[
          const SizedBox(height: AppTokens.spaceLg),
          Text(l.playerGuardians, style: theme.textTheme.titleMedium),
          ref
              .watch(_guardiansOfPlayerProvider(player.id))
              .when(
                data: (links) => links.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTokens.spaceSm,
                        ),
                        child: Text(
                          l.playerNoGuardians,
                          key: const Key('player-no-guardians'),
                        ),
                      )
                    : Column(
                        children: [
                          for (final g in links)
                            ListTile(
                              key: Key('guardian-${g.id}'),
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.family_restroom_outlined,
                              ),
                              title: Text(g.guardian.displayName),
                            ),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppTokens.spaceMd),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(AppErrorText.of(e, l)),
              ),
        ],
        if (canWithdraw) ...[
          const SizedBox(height: AppTokens.spaceLg),
          OutlinedButton.icon(
            key: const Key('player-withdraw'),
            icon: const Icon(Icons.logout),
            label: Text(l.playerWithdraw),
            onPressed: () => _withdraw(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final reason = await noteDialog(
      context,
      title: l.playerWithdrawConfirm(player.displayName),
      confirmLabel: l.playerWithdraw,
      label: l.playerWithdrawReason,
    );
    if (reason == null || !context.mounted) return;
    await runAction(context, () async {
      final result = await ref
          .read(playerDetailProvider(player.id).notifier)
          .withdraw(reason: reason.isEmpty ? null : reason);
      if (!context.mounted) return;
      final pending =
          result.approvalRequest.status == api.ApprovalStatus.PENDING;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending ? l.playerWithdrawRequested : l.playerWithdrawn,
          ),
        ),
      );
    });
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXs),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

/// Eligible teams for a player in the active season, with play-up badges.
class EligibleTeamsDialog extends ConsumerStatefulWidget {
  const EligibleTeamsDialog({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<EligibleTeamsDialog> createState() =>
      _EligibleTeamsDialogState();
}

class _EligibleTeamsDialogState extends ConsumerState<EligibleTeamsDialog> {
  late final Future<List<api.EligibleTeam>> _teams = _load();

  Future<List<api.EligibleTeam>> _load() async {
    final season = await ref.read(activeSeasonProvider.future);
    if (season == null) return const [];
    return ref
        .read(playerDetailProvider(widget.playerId).notifier)
        .eligibleTeams(season.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.playerAssignToTeam),
      content: SizedBox(
        width: 360,
        child: FutureBuilder<List<api.EligibleTeam>>(
          future: _teams,
          builder: (context, snap) {
            if (snap.hasError) return Text(AppErrorText.of(snap.error!, l));
            final teams = snap.data;
            if (teams == null) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (teams.isEmpty) {
              return Text(
                l.playerNoEligibleTeams,
                key: const Key('no-eligible-teams'),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final e in teams)
                  ListTile(
                    key: Key('eligible-${e.team.id}'),
                    title: Text(e.team.displayLabel),
                    subtitle: EligibilityBadge(
                      result: e.eligibility.result,
                      playUpLevels: e.eligibility.playUpLevels ?? 0,
                    ),
                    onTap: () async {
                      final ok = await runAction(
                        context,
                        () => ref
                            .read(
                              playerDetailProvider(widget.playerId).notifier,
                            )
                            .assignTo(e.team.id),
                        success: l.rosterAssigned,
                      );
                      if (ok && context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- create

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({super.key});

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _form = GlobalKey<FormState>();
  final _given = TextEditingController();
  final _family = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  api.Date? _birth;
  bool _birthTouched = false;
  api.Gender _gender = api.Gender.MALE;
  String? _teamId;
  bool _busy = false;

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth?.toDateTime() ?? DateTime(DateTime.now().year - 12),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birth = api.Date(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    setState(() => _birthTouched = true);
    if (!_form.currentState!.validate() || _birth == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    var created = false;
    await runAction(context, () async {
      final result = await ref
          .read(playersProvider.notifier)
          .create(
            api.CreatePlayerRequest(
              (b) => b
                ..givenName = _given.text.trim()
                ..familyName = _family.text.trim()
                ..birthDate = _birth
                ..gender = _gender
                ..email = _email.text.trim().isEmpty ? null : _email.text.trim()
                ..teamId = _teamId
                ..note = _note.text.trim().isEmpty ? null : _note.text.trim(),
            ),
          );
      created = true;
      if (!mounted) return;
      final pending =
          result.approvalRequest.status == api.ApprovalStatus.PENDING;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pending ? l.playerRequestSent : l.playerCreated),
        ),
      );
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (created) context.go('/players');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final isRequest = caps.canRequestPlayer;
    final teams = [
      for (final t in ref.watch(teamsProvider).value ?? const <api.Team>[])
        if (caps.canEditRoster(t.id)) t,
    ];
    return SubPage(
      title: isRequest ? l.playerNewRequest : l.playerNew,
      parentPath: '/players',
      child: Guarded(
        allowed: caps.canCreatePlayerDirectly || caps.canRequestPlayer,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            children: [
              TextFormField(
                key: const Key('player-given'),
                controller: _given,
                decoration: InputDecoration(labelText: l.playerGivenName),
                validator: (v) => requiredValidator(l, v),
              ),
              const SizedBox(height: AppTokens.spaceMd),
              TextFormField(
                key: const Key('player-family'),
                controller: _family,
                decoration: InputDecoration(labelText: l.playerFamilyName),
                validator: (v) => requiredValidator(l, v),
              ),
              const SizedBox(height: AppTokens.spaceMd),
              OutlinedButton(
                key: const Key('player-birth'),
                onPressed: _pickBirth,
                child: Text(
                  '${l.playerBirthDate}: ${_birth == null ? '-' : formatDate(_birth!)}',
                ),
              ),
              if (_birthTouched && _birth == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTokens.spaceXs),
                  child: Text(
                    l.playerBirthDateInvalid,
                    key: const Key('player-birth-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppTokens.spaceMd),
              DropdownButtonFormField<api.Gender>(
                isExpanded: true,
                key: const Key('player-gender'),
                initialValue: _gender,
                decoration: InputDecoration(labelText: l.playerGender),
                items: [
                  for (final g in [api.Gender.MALE, api.Gender.FEMALE])
                    DropdownMenuItem(value: g, child: Text(g.label(l))),
                ],
                onChanged: (v) => _gender = v ?? _gender,
              ),
              const SizedBox(height: AppTokens.spaceMd),
              TextFormField(
                key: const Key('player-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l.playerEmail),
                validator: (v) {
                  final t = (v ?? '').trim();
                  return t.isEmpty ||
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                      ? null
                      : l.fieldInvalidEmail;
                },
              ),
              const SizedBox(height: AppTokens.spaceMd),
              DropdownButtonFormField<String?>(
                key: const Key('player-team'),
                isExpanded: true,
                decoration: InputDecoration(labelText: l.playerInitialTeam),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                  for (final t in teams)
                    DropdownMenuItem<String?>(
                      value: t.id,
                      child: Text(t.displayLabel),
                    ),
                ],
                onChanged: (v) => _teamId = v,
              ),
              if (isRequest) ...[
                const SizedBox(height: AppTokens.spaceMd),
                TextFormField(
                  key: const Key('player-note'),
                  controller: _note,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.playerNote),
                ),
              ],
              const SizedBox(height: AppTokens.spaceLg),
              FilledButton(
                key: const Key('player-submit'),
                onPressed: _busy ? null : _submit,
                child: Text(isRequest ? l.playerNewRequest : l.create),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
