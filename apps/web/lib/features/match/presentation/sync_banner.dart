import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/match_providers.dart';
import '../application/sync/sync_status.dart';

/// "N unsynced" strip with a retry button; also explains a paused (401)
/// queue and rejected events. Hidden when everything is synced.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final worker = ref.watch(syncWorkerProvider);
    final unsynced = ref.watch(unsyncedCountProvider).value ?? 0;
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: worker.status,
      builder: (context, status, _) {
        final rejected = status.rejectedCount;
        if (unsynced == 0 && rejected == 0 && !status.pausedForAuth)
          return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final parts = [
          if (status.pausedForAuth) l.matchSyncPausedAuth,
          if (unsynced > 0) l.matchUnsynced(unsynced),
          if (rejected > 0) l.matchRejectedCount(rejected),
        ];
        return Material(
          key: const Key('sync-banner'),
          color: status.pausedForAuth || rejected > 0
              ? scheme.errorContainer
              : scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
            child: Row(
              children: [
                Icon(
                  status.syncing ? Icons.sync : Icons.cloud_off_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppTokens.spaceSm),
                Expanded(
                  child: Text(
                    status.syncing ? l.matchSyncing : parts.join(' · '),
                  ),
                ),
                if (!status.pausedForAuth && unsynced > 0)
                  TextButton(
                    key: const Key('sync-retry'),
                    onPressed: status.syncing ? null : () => worker.syncNow(),
                    child: Text(l.retry),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
