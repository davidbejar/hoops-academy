import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/ui/async_body.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/session/capabilities.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_providers.dart';
import '../application/finance_rights.dart';

/// Who of a team is up to date, a marker per player and no amounts, on the
/// team's screen. Only for the team's current COACH (decision 96): anyone else
/// gets nothing here, and a refusal (403) of the service hides it too.
class DueStatusSection extends ConsumerWidget {
  const DueStatusSection({
    super.key,
    required this.teamId,
    required this.staff,
  });

  final String teamId;
  final List<api.TeamStaffMember> staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(capabilitiesProvider);
    if (!caps.canSeeTeamDueStatus(teamId, staff: staff)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final status = ref.watch(teamDueStatusProvider(teamId));
    if (status.value == null &&
        status.hasError &&
        AppError.of(status.error!).kind == AppErrorKind.forbidden) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      key: const Key('due-status'),
      title: l.financeCoachTitle,
      child: AsyncSection<fin.TeamDueStatus>(
        value: status,
        retryKey: const Key('due-status-retry'),
        onRetry: () => ref.invalidate(teamDueStatusProvider(teamId)),
        builder: (context, data) => _Players(status: data),
      ),
    );
  }
}

class _Players extends StatelessWidget {
  const _Players({required this.status});

  final fin.TeamDueStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: HoopsTokens.colorsOf(context).inkMuted);
    final players = status.players;
    if (players.isEmpty) {
      return Text(
        l.financeCoachEmpty,
        key: const Key('due-status-empty'),
        style: muted,
      );
    }
    final behind = players.where((p) => !p.upToDate).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HoopsSpace.sm,
      children: [
        Text(
          l.financeCoachBehindCount(behind, players.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(l.financeCoachNote, style: muted),
        for (final p in players)
          ListRow(
            key: Key('due-status-${p.playerId}'),
            leading: IconTile(
              p.upToDate ? Icons.check_circle_outline : Icons.schedule,
              tone: p.upToDate ? HoopsTone.success : HoopsTone.warning,
            ),
            title: p.playerName.isEmpty ? '—' : p.playerName,
            subtitle: p.upToDate
                ? l.financeCoachUpToDate
                : l.financeCoachBehind,
          ),
      ],
    );
  }
}
