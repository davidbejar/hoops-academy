import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/admin_providers.dart';

class SeasonsScreen extends ConsumerWidget {
  const SeasonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final seasons = ref.watch(seasonsProvider);
    return SubPage(
      title: l.adminSeasons,
      parentPath: '/admin',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('season-new'),
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => const SeasonDialog(),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.seasonNew),
      ),
      child: AsyncBody<List<api.Season>>(
        value: seasons,
        onRetry: () => ref.invalidate(seasonsProvider),
        isEmpty: (d) => d.isEmpty,
        emptyMessage: l.seasonsEmpty,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final s in data.reversed)
              ListTile(
                key: Key('season-${s.id}'),
                title: Row(
                  children: [
                    Flexible(child: Text(s.name)),
                    if (s.current) ...[
                      const SizedBox(width: AppTokens.spaceSm),
                      InfoChip(l.seasonCurrent, tone: ChipTone.good),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${formatDate(s.startsOn)} - ${formatDate(s.endsOn)}',
                ),
                onTap: () => showDialog<bool>(
                  context: context,
                  builder: (_) => SeasonDialog(season: s),
                ),
                trailing: IconButton(
                  key: Key('season-rollover-${s.id}'),
                  tooltip: l.seasonRollover,
                  icon: const Icon(Icons.skip_next_outlined),
                  onPressed: () =>
                      context.go('/admin/seasons/${s.id}/rollover'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SeasonDialog extends ConsumerStatefulWidget {
  const SeasonDialog({super.key, this.season});
  final api.Season? season;

  @override
  ConsumerState<SeasonDialog> createState() => _SeasonDialogState();
}

class _SeasonDialogState extends ConsumerState<SeasonDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.season?.name);
  late final _year = TextEditingController(
    text: (widget.season?.referenceYear ?? DateTime.now().year).toString(),
  );
  late api.Date? _start = widget.season?.startsOn;
  late api.Date? _end = widget.season?.endsOn;
  bool _datesTouched = false;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final now = DateTime.now();
    final initial = (start ? _start : _end)?.toDateTime() ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final d = api.Date(picked.year, picked.month, picked.day);
      start ? _start = d : _end = d;
    });
  }

  bool get _datesOk =>
      _start != null && _end != null && _end!.compareTo(_start!) > 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final editing = widget.season != null;
    return FormDialog(
      title: editing ? l.seasonEdit : l.seasonNew,
      formKey: _form,
      validateExtra: () {
        setState(() => _datesTouched = true);
        return _datesOk;
      },
      onSubmit: () {
        final notifier = ref.read(seasonsProvider.notifier);
        final year = int.parse(_year.text.trim());
        return runAction(
          context,
          () => editing
              ? notifier.edit(
                  widget.season!.id,
                  name: _name.text.trim(),
                  startsOn: _start!,
                  endsOn: _end!,
                  referenceYear: year,
                )
              : notifier.create(
                  name: _name.text.trim(),
                  startsOn: _start!,
                  endsOn: _end!,
                  referenceYear: year,
                ),
          success: l.saved,
        );
      },
      children: [
        TextFormField(
          key: const Key('season-name'),
          controller: _name,
          decoration: InputDecoration(labelText: l.seasonName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        OutlinedButton(
          key: const Key('season-start'),
          onPressed: () => _pick(true),
          child: Text(
            '${l.seasonStarts}: ${_start == null ? '-' : formatDate(_start!)}',
          ),
        ),
        formGap,
        OutlinedButton(
          key: const Key('season-end'),
          onPressed: () => _pick(false),
          child: Text(
            '${l.seasonEnds}: ${_end == null ? '-' : formatDate(_end!)}',
          ),
        ),
        if (_datesTouched && !_datesOk)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spaceSm),
            child: Text(
              l.seasonDatesInvalid,
              key: const Key('season-dates-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        formGap,
        TextFormField(
          key: const Key('season-year'),
          controller: _year,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.seasonReferenceYear),
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            return n == null || n < 1990 || n > 2100
                ? l.fieldInvalidNumber
                : null;
          },
        ),
      ],
    );
  }
}

/// Rollover wizard: confirm -> run -> result with the orphan list.
class RolloverScreen extends ConsumerStatefulWidget {
  const RolloverScreen({super.key, required this.seasonId});
  final String seasonId;

  @override
  ConsumerState<RolloverScreen> createState() => _RolloverScreenState();
}

class _RolloverScreenState extends ConsumerState<RolloverScreen> {
  bool _cloneStaff = true;
  bool _clonePlayers = true;
  bool _busy = false;
  api.SeasonRolloverResult? _result;

  Future<void> _run() async {
    setState(() => _busy = true);
    final ok = await runAction(context, () async {
      _result = await ref
          .read(seasonsProvider.notifier)
          .rollover(
            widget.seasonId,
            cloneStaff: _cloneStaff,
            clonePlayers: _clonePlayers,
          );
    });
    if (mounted) setState(() => _busy = false);
    if (!ok) _result = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final seasons = ref.watch(seasonsProvider);
    String? name;
    for (final s in seasons.value ?? const <api.Season>[]) {
      if (s.id == widget.seasonId) name = s.name;
    }
    final result = _result;
    return SubPage(
      title: l.rolloverTitle,
      parentPath: '/admin/seasons',
      child: AsyncBody<List<api.Season>>(
        value: seasons,
        onRetry: () => ref.invalidate(seasonsProvider),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          children: [
            if (result == null) ...[
              Text(
                l.rolloverIntro(name ?? ''),
                key: const Key('rollover-intro'),
              ),
              CheckboxListTile(
                key: const Key('rollover-clone-staff'),
                value: _cloneStaff,
                title: Text(l.rolloverCloneStaff),
                onChanged: (v) => setState(() => _cloneStaff = v ?? true),
              ),
              CheckboxListTile(
                key: const Key('rollover-clone-players'),
                value: _clonePlayers,
                title: Text(l.rolloverClonePlayers),
                onChanged: (v) => setState(() => _clonePlayers = v ?? true),
              ),
              const SizedBox(height: AppTokens.spaceMd),
              FilledButton(
                key: const Key('rollover-run'),
                onPressed: _busy ? null : _run,
                child: Text(l.rolloverConfirm),
              ),
            ] else ...[
              Text(
                l.rolloverDone,
                style: theme.textTheme.titleLarge,
                key: const Key('rollover-done'),
              ),
              const SizedBox(height: AppTokens.spaceSm),
              Text(l.rolloverClonedTeams(result.clonedTeams.length.toString())),
              Text(
                l.rolloverCasesOpened(result.openedCaseIds.length.toString()),
              ),
              const SizedBox(height: AppTokens.spaceMd),
              Text(l.rolloverOrphansTitle, style: theme.textTheme.titleMedium),
              if (result.orphans.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.spaceSm,
                  ),
                  child: Text(
                    l.rolloverNoOrphans,
                    key: const Key('rollover-no-orphans'),
                  ),
                )
              else
                for (final o in result.orphans)
                  ListTile(
                    key: Key('orphan-${o.player.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l.rolloverOrphanLine(
                        o.player.displayName,
                        o.previousTeam?.name ?? '-',
                      ),
                    ),
                    subtitle: Text(
                      o.reasons.map((r) => r.label(l)).join(' · '),
                    ),
                  ),
              const SizedBox(height: AppTokens.spaceMd),
              FilledButton.icon(
                key: const Key('rollover-go-cases'),
                icon: const Icon(Icons.report_problem_outlined),
                label: Text(l.rolloverGoToCases),
                onPressed: () => context.go('/teams/cases'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
