import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/match_providers.dart';
import '../application/sync/sync_status.dart';

/// "N unsynced" strip with a retry button; also explains a paused (401)
/// queue and rejected events (danger tone). Hidden when everything is synced.
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
        final parts = [
          if (status.pausedForAuth) l.matchSyncPausedAuth,
          if (unsynced > 0) l.matchUnsynced(unsynced),
          if (rejected > 0) l.matchRejectedCount(rejected),
        ];
        return NoticeBanner(
          key: const Key('sync-banner'),
          tone: status.pausedForAuth || rejected > 0
              ? HoopsTone.danger
              : HoopsTone.warning,
          icon: status.syncing ? Icons.sync : Icons.cloud_off_outlined,
          message: status.syncing ? l.matchSyncing : parts.join(' · '),
          action: !status.pausedForAuth && unsynced > 0
              ? TextButton(
                  key: const Key('sync-retry'),
                  onPressed: status.syncing ? null : () => worker.syncNow(),
                  child: Text(l.retry),
                )
              : null,
        );
      },
    );
  }
}
