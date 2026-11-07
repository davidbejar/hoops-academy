import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart' show seasonsProvider;
import '../application/roster_providers.dart';
import '../application/season_view.dart';

/// The season selector of the lists (WP80, ADR-0042): the current season by default, past seasons readable for
/// an admin and for staff with history, and a banner while one is on screen (every write is off then). Nothing for
/// anybody else. [onChanged] lets a list jump to the matching period (the calendar to the season's last week).
class SeasonBar extends ConsumerWidget {
  const SeasonBar({
    super.key,
    this.onChanged,
    this.padding = const EdgeInsets.only(top: HoopsSpace.md),
  });

  final void Function(api.Season? season)? onChanged;

  /// Room around the bar; none at all while the bar is not shown.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(capabilitiesProvider).canBrowseSeasons) {
      return const SizedBox.shrink();
    }
    final seasons = ref.watch(seasonsProvider).value ?? const <api.Season>[];
    if (seasons.length < 2) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final active = ref.watch(activeSeasonProvider).value;
    final current = seasons.where((s) => s.current).firstOrNull;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HoopsSpace.gap,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('season-bar'),
            initialValue: active?.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.seasonBarLabel),
            items: [
              for (final s in seasons)
                DropdownMenuItem(value: s.id, child: Text(s.name)),
            ],
            onChanged: (id) {
              final chosen = seasons.where((s) => s.id == id).firstOrNull;
              ref
                  .read(selectedSeasonIdProvider.notifier)
                  .select(id == current?.id ? null : id);
              onChanged?.call(chosen);
            },
          ),
          if (ref.watch(viewingPastSeasonProvider))
            ClipRRect(
              borderRadius: BorderRadius.circular(HoopsRadius.md),
              child: NoticeBanner(
                key: const Key('past-season-banner'),
                tone: HoopsTone.info,
                icon: Icons.lock_outline,
                message: l.pastSeasonBanner,
              ),
            ),
        ],
      ),
    );
  }
}
