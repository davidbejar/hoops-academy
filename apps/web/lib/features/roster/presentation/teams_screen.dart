import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart';
import '../../health/presentation/player_health_view.dart' show AvailabilityBadge;
import '../application/roster_providers.dart';
import 'eligibility_widgets.dart';

/// Teams of the selected season (deferred module behind the Teams tab).
class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final teams = ref.watch(teamsProvider);
    final seasons = ref.watch(seasonsProvider);
    final season = ref.watch(activeSeasonProvider).value;
    return Scaffold(
      floatingActionButton: caps.canManageTeams && season != null
          ? FloatingActionButton.extended(
              key: const Key('team-new'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const TeamDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.teamNew),
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
                      child: DropdownButtonFormField<String>(
                        key: const Key('season-select'),
                        initialValue: season?.id,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.teamsSeason),
                        items: [
                          for (final s in seasons.value ?? const <api.Season>[])
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                        ],
                        onChanged: (v) => ref
                            .read(selectedSeasonIdProvider.notifier)
                            .select(v),
                      ),
                    ),
                    if (caps.canSeeApprovals || caps.canSeeModule)
                      IconButton(
                        key: const Key('open-cases'),
                        tooltip: l.adminCases,
                        icon: const Icon(Icons.report_problem_outlined),
                        onPressed: () => context.go('/teams/cases'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: seasons.hasValue && (seasons.value ?? const []).isEmpty
                    ? EmptyView(message: l.teamsNoSeason)
                    : AsyncBody<List<api.Team>>(
                        value: teams,
                        onRetry: () => ref.invalidate(teamsProvider),
                        isEmpty: (d) => d.isEmpty,
                        emptyMessage: l.teamsEmpty,
                        builder: (context, data) => ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceMd,
                            AppTokens.spaceSm,
                            AppTokens.spaceMd,
                            88,
                          ),
                          children: [for (final t in data) TeamCard(team: t)],
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

class TeamCard extends ConsumerWidget {
  const TeamCard({super.key, required this.team});
  final api.Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mine = ref.watch(capabilitiesProvider).isStaffOf(team.id);
    return Card(
      child: InkWell(
        key: Key('team-${team.id}'),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        onTap: () => context.go('/teams/${team.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text(
                  team.ageCategory.code,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.displayLabel, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTokens.spaceXs),
                    Wrap(
                      spacing: AppTokens.spaceSm,
                      runSpacing: AppTokens.spaceXs,
                      children: [
                        InfoChip(team.ageCategory.name),
                        InfoChip(team.genderPolicy.label(l)),
                        InfoChip(
                          l.teamPlayerCount(team.playerCount.toString()),
                          icon: Icons.person_outline,
                        ),
                        if (mine)
                          InfoChip(
                            l.roleCoach,
                            tone: ChipTone.good,
                            icon: Icons.sports,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamDialog extends ConsumerStatefulWidget {
  const TeamDialog({super.key, this.team});
  final api.Team? team;

  @override
  ConsumerState<TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends ConsumerState<TeamDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.team?.name);
  late final _alias = TextEditingController(text: widget.team?.alias);
  late String? _categoryId = widget.team?.ageCategory.id;
  late api.GenderPolicy _policy =
      widget.team?.genderPolicy ?? api.GenderPolicy.MIXED;

  @override
  void dispose() {
    _name.dispose();
    _alias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories =
        ref.watch(ageCategoriesProvider).value ?? const <api.AgeCategory>[];
    return FormDialog(
      title: widget.team == null ? l.teamNew : l.teamEdit,
      formKey: _form,
      canSubmit: categories.isNotEmpty,
      onSubmit: () {
        final alias = _alias.text.trim().isEmpty ? null : _alias.text.trim();
        final notifier = ref.read(teamsProvider.notifier);
        return runAction(context, () async {
          if (widget.team == null) {
            await notifier.create(
              name: _name.text.trim(),
              alias: alias,
              ageCategoryId: _categoryId!,
              genderPolicy: _policy,
            );
          } else {
            await notifier.edit(
              widget.team!.id,
              name: _name.text.trim(),
              alias: alias,
              ageCategoryId: _categoryId!,
              genderPolicy: _policy,
            );
            ref.invalidate(teamDetailProvider(widget.team!.id));
          }
        }, success: l.saved);
      },
      children: [
        TextFormField(
          key: const Key('team-name'),
          controller: _name,
          decoration: InputDecoration(labelText: l.teamName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('team-alias'),
          controller: _alias,
          decoration: InputDecoration(labelText: l.teamAlias),
        ),
        formGap,
        DropdownButtonFormField<String>(
          key: const Key('team-category'),
          initialValue: _categoryId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.teamCategory),
          items: [
            for (final c in categories)
              DropdownMenuItem(
                value: c.id,
                child: Text('${c.code} · ${c.name}'),
              ),
          ],
          validator: (v) => v == null ? l.fieldRequired : null,
          onChanged: (v) => _categoryId = v,
        ),
        formGap,
        DropdownButtonFormField<api.GenderPolicy>(
          isExpanded: true,
          key: const Key('team-policy'),
          initialValue: _policy,
          decoration: InputDecoration(labelText: l.teamGenderPolicy),
          items: [
            for (final p in [
              api.GenderPolicy.MALE,
              api.GenderPolicy.FEMALE,
              api.GenderPolicy.MIXED,
            ])
              DropdownMenuItem(value: p, child: Text(p.label(l))),
          ],
          onChanged: (v) => _policy = v ?? _policy,
        ),
      ],
    );
  }
}

/// Team detail: header, staff and roster with the role-aware actions.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final detail = ref.watch(teamDetailProvider(teamId));
    final canEdit = caps.canEditRoster(teamId);
    return SubPage(
      title: detail.value?.team.displayLabel ?? l.navTeams,
      parentPath: '/teams',
      actions: [
        if (caps.canManageTeams && detail.hasValue)
          IconButton(
            key: const Key('team-edit'),
            tooltip: l.teamEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => TeamDialog(team: detail.value!.team),
            ),
          ),
      ],
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('roster-assign'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => AssignPlayerDialog(teamId: teamId),
              ),
              icon: const Icon(Icons.person_add_alt),
              label: Text(l.rosterAssign),
            )
          : null,
      child: AsyncBody<TeamDetail>(
        value: detail,
        onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
        builder: (context, data) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceMd,
            AppTokens.spaceMd,
            AppTokens.spaceMd,
            96,
          ),
          children: [
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceXs,
              children: [
                InfoChip(data.team.ageCategory.name),
                InfoChip(data.team.genderPolicy.label(l)),
                if (!canEdit)
                  InfoChip(
                    l.readOnlyHint,
                    key: const Key('read-only'),
                    icon: Icons.lock_outline,
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceLg),
            _StaffSection(teamId: teamId, staff: data.staff),
            const SizedBox(height: AppTokens.spaceLg),
            _RosterSection(
              teamId: teamId,
              roster: data.roster,
              canEdit: canEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffSection extends ConsumerWidget {
  const _StaffSection({required this.teamId, required this.staff});
  final String teamId;
  final List<api.TeamStaffMember> staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final canManage = ref.watch(capabilitiesProvider).canManageTeams;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.teamStaff,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canManage)
              TextButton.icon(
                key: const Key('staff-add'),
                icon: const Icon(Icons.add),
                label: Text(l.teamStaffAdd),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => AddStaffDialog(teamId: teamId),
                ),
              ),
          ],
        ),
        if (staff.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
            child: Text(l.teamStaffNone, key: const Key('staff-none')),
          ),
        for (final s in staff)
          ListTile(
            key: Key('staff-${s.person.personId}'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sports),
            title: Text(s.person.displayName),
            subtitle: Text(s.role.label(l)),
            trailing: canManage
                ? IconButton(
                    tooltip: l.remove,
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () async {
                      if (!await confirmDialog(
                        context,
                        message: l.teamStaffRemoveConfirm(s.person.displayName),
                      )) {
                        return;
                      }
                      if (!context.mounted) return;
                      await runAction(
                        context,
                        () => ref
                            .read(teamDetailProvider(teamId).notifier)
                            .removeStaff(s.person.personId),
                      );
                    },
                  )
                : null,
          ),
      ],
    );
  }
}

class _RosterSection extends ConsumerWidget {
  const _RosterSection({
    required this.teamId,
    required this.roster,
    required this.canEdit,
  });
  final String teamId;
  final List<api.TeamPlayer> roster;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.teamRoster, style: Theme.of(context).textTheme.titleMedium),
        if (roster.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
            child: Text(l.teamRosterEmpty, key: const Key('roster-empty')),
          ),
        for (final tp in roster)
          ListTile(
            key: Key('roster-${tp.player.id}'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(tp.jerseyNumber ?? '-')),
            title: Text(tp.player.displayName),
            subtitle: Wrap(
              spacing: AppTokens.spaceSm,
              children: [
                AvailabilityBadge(playerId: tp.player.id),
                if (tp.playUpLevels > 0) PlayUpBadge(levels: tp.playUpLevels),
                if (tp.invalidatedAt != null)
                  InfoChip(
                    l.rosterInvalid,
                    tone: ChipTone.bad,
                    icon: Icons.warning_amber,
                  ),
              ],
            ),
            onTap: () => context.go('/players/${tp.player.id}'),
            trailing: canEdit
                ? PopupMenuButton<String>(
                    key: Key('roster-menu-${tp.player.id}'),
                    tooltip: l.moreActions,
                    onSelected: (action) => _onAction(context, ref, tp, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'jersey',
                        child: Text(l.rosterJerseyEdit),
                      ),
                      PopupMenuItem(
                        value: 'unassign',
                        child: Text(l.rosterUnassign),
                      ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    api.TeamPlayer tp,
    String action,
  ) async {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(teamDetailProvider(teamId).notifier);
    if (action == 'unassign') {
      if (!await confirmDialog(
        context,
        message: l.rosterUnassignConfirm(tp.player.displayName),
      )) {
        return;
      }
      if (!context.mounted) return;
      await runAction(context, () => notifier.unassign(tp.player.id));
    } else {
      final jersey = await noteDialog(
        context,
        title: l.rosterJerseyEdit,
        confirmLabel: l.save,
        required: true,
        label: l.rosterJersey,
      );
      if (jersey == null || !context.mounted) return;
      await runAction(
        context,
        () => notifier.setJersey(tp.player.id, jersey),
        success: l.saved,
      );
    }
  }
}

class AddStaffDialog extends ConsumerStatefulWidget {
  const AddStaffDialog({super.key, required this.teamId});
  final String teamId;

  @override
  ConsumerState<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<AddStaffDialog> {
  final _form = GlobalKey<FormState>();
  late final Future<List<api.Member>> _members = ref
      .read(membersRepositoryProvider)
      .list(active: true);
  String? _personId;
  api.StaffRole _role = api.StaffRole.COACH;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<List<api.Member>>(
      future: _members,
      builder: (context, snap) {
        final members = [
          for (final m in snap.data ?? const <api.Member>[])
            if (m.roles.contains(api.TenantRole.COACH) ||
                m.roles.contains(api.TenantRole.ASSISTANT_COACH))
              m,
        ];
        return FormDialog(
          title: l.teamStaffAdd,
          formKey: _form,
          canSubmit: snap.hasData,
          onSubmit: () => runAction(
            context,
            () => ref
                .read(teamDetailProvider(widget.teamId).notifier)
                .addStaff(_personId!, _role),
            success: l.saved,
          ),
          children: [
            DropdownButtonFormField<String>(
              key: const Key('staff-person'),
              isExpanded: true,
              decoration: InputDecoration(labelText: l.teamStaffPick),
              items: [
                for (final m in members)
                  DropdownMenuItem(
                    value: m.personId,
                    child: Text(m.displayName),
                  ),
              ],
              validator: (v) => v == null ? l.fieldRequired : null,
              onChanged: (v) => _personId = v,
            ),
            formGap,
            DropdownButtonFormField<api.StaffRole>(
              isExpanded: true,
              key: const Key('staff-role'),
              initialValue: _role,
              decoration: InputDecoration(labelText: l.teamStaffRole),
              items: [
                for (final r in [
                  api.StaffRole.COACH,
                  api.StaffRole.ASSISTANT_COACH,
                ])
                  DropdownMenuItem(value: r, child: Text(r.label(l))),
              ],
              onChanged: (v) => _role = v ?? _role,
            ),
          ],
        );
      },
    );
  }
}

/// Pick a player, see the eligibility verdict for this team, then assign.
class AssignPlayerDialog extends ConsumerStatefulWidget {
  const AssignPlayerDialog({super.key, required this.teamId});
  final String teamId;

  @override
  ConsumerState<AssignPlayerDialog> createState() => _AssignPlayerDialogState();
}

class _AssignPlayerDialogState extends ConsumerState<AssignPlayerDialog> {
  final _jersey = TextEditingController();
  late Future<List<api.Player>> _players = ref
      .read(playersRepositoryProvider)
      .list();
  api.Player? _selected;
  Future<api.EligibilityCheck>? _check;
  bool _busy = false;

  @override
  void dispose() {
    _jersey.dispose();
    super.dispose();
  }

  void _select(api.Player p) => setState(() {
    _selected = p;
    _check = ref.read(teamDetailProvider(widget.teamId).notifier).check(p.id);
  });

  Future<void> _assign() async {
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final jersey = _jersey.text.trim().isEmpty ? null : _jersey.text.trim();
    final ok = await runAction(
      context,
      () => ref
          .read(teamDetailProvider(widget.teamId).notifier)
          .assign(_selected!.id, jerseyNumber: jersey),
      success: l.rosterAssigned,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final onTeam = {
      for (final tp
          in ref.watch(teamDetailProvider(widget.teamId)).value?.roster ??
              const <api.TeamPlayer>[])
        tp.player.id,
    };
    return AlertDialog(
      title: Text(l.rosterAssign),
      content: SizedBox(
        width: 360,
        height: 420,
        child: _selected == null
            ? Column(
                children: [
                  TextField(
                    key: const Key('assign-search'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.rosterSearchPlayer,
                    ),
                    onSubmitted: (v) => setState(
                      () => _players = ref
                          .read(playersRepositoryProvider)
                          .list(query: v),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<api.Player>>(
                      future: _players,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(child: Text(l.errorUnknown));
                        }
                        final all = snap.data;
                        if (all == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final candidates = [
                          for (final p in all)
                            if (!onTeam.contains(p.id) &&
                                (p.status == api.PlayerStatus.ACTIVE ||
                                    p.status == api.PlayerStatus.ORPHAN))
                              p,
                        ];
                        if (candidates.isEmpty) {
                          return Center(child: Text(l.noResults));
                        }
                        return ListView(
                          children: [
                            for (final p in candidates)
                              ListTile(
                                key: Key('assign-candidate-${p.id}'),
                                title: Text(p.displayName),
                                subtitle: Text(p.naturalCategory?.name ?? ''),
                                onTap: () => _select(p),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  Text(
                    _selected!.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  FutureBuilder<api.EligibilityCheck>(
                    future: _check,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Text(
                          AppErrorText.of(snap.error!, l),
                          key: const Key('check-error'),
                        );
                      }
                      final check = snap.data;
                      if (check == null) {
                        return Text(l.rosterEligibilityPending);
                      }
                      return EligibilityPanel(check: check);
                    },
                  ),
                  const SizedBox(height: AppTokens.spaceMd),
                  TextField(
                    key: const Key('assign-jersey'),
                    controller: _jersey,
                    decoration: InputDecoration(labelText: l.rosterJersey),
                  ),
                ],
              ),
      ),
      actions: [
        if (_selected != null)
          TextButton(
            onPressed: _busy ? null : () => setState(() => _selected = null),
            child: Text(l.back),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        if (_selected != null)
          FutureBuilder<api.EligibilityCheck>(
            future: _check,
            builder: (context, snap) {
              final ok =
                  snap.hasData &&
                  snap.data!.result != api.EligibilityResult.INELIGIBLE;
              return FilledButton(
                key: const Key('assign-confirm'),
                onPressed: ok && !_busy ? _assign : null,
                child: Text(l.rosterAssign),
              );
            },
          ),
      ],
    );
  }
}
